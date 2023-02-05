#include <string.h>
#include <sys/param.h>
#include <driver/gpio.h>
#include <lwip/netdb.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_netif.h"
#include "listener.h"

#include "lwip/err.h"
#include "lwip/sockets.h"
#include "lwip/sys.h"

uint16_t processCommand(uint16_t command);

#define PORT 42069 
#define LED_PIN 21
static const char *TAG = "example";

// 
// Command structure:
// Clients send commands in the following format:
// 0000 0000 0000 0000
// ^^|---------------|
// ||        | 
// ||        \--------> For command `10` The amount of time, in seconds to turn on for (for turn on command). Otherwise unused (zero is recommended)
// ||  
// \\-----------------> The command to send `00` for turn off, `01` for status, `10` for turn on
// 
// Server always replies with its status, either:
//  - `0000 0000 0000 0000` for off
//  - `10XX XXXX XXXX XXXX` for on, with the Xs being the time remaining in seconds

uint16_t currentStatus = 0x00000000;

uint16_t getCurrentStatus() {
    return currentStatus;
}

void udp_server_task(void *pvParameters)
{
    char rx_buffer[128];
    char addr_str[128];
    int addr_family = (int)pvParameters;
    int ip_protocol = 0;
    struct sockaddr_in6 dest_addr;

    while (1) {

        if (addr_family == AF_INET) {
            struct sockaddr_in *dest_addr_ip4 = (struct sockaddr_in *)&dest_addr;
            dest_addr_ip4->sin_addr.s_addr = htonl(INADDR_ANY);
            dest_addr_ip4->sin_family = AF_INET;
            dest_addr_ip4->sin_port = htons(PORT);
            ip_protocol = IPPROTO_IP;
        } else if (addr_family == AF_INET6) {
            bzero(&dest_addr.sin6_addr.un, sizeof(dest_addr.sin6_addr.un));
            dest_addr.sin6_family = AF_INET6;
            dest_addr.sin6_port = htons(PORT);
            ip_protocol = IPPROTO_IPV6;
        }

        int sock = socket(addr_family, SOCK_DGRAM, ip_protocol);
        if (sock < 0) {
            ESP_LOGE(TAG, "Unable to create socket: errno %d", errno);
            break;
        }
        ESP_LOGI(TAG, "Socket created");

        int enable = 1;
        lwip_setsockopt(sock, IPPROTO_IP, IP_PKTINFO, &enable, sizeof(enable));

        // Set timeout
        struct timeval timeout;
        timeout.tv_sec = 10;
        timeout.tv_usec = 0;
        setsockopt (sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof timeout);

        int err = bind(sock, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
        if (err < 0) {
            ESP_LOGE(TAG, "Socket unable to bind: errno %d", errno);
        }
        ESP_LOGI(TAG, "Socket bound, port %d", PORT);

        struct sockaddr_storage source_addr; // Large enough for both IPv4 or IPv6
        socklen_t socklen = sizeof(source_addr);

        struct iovec iov;
        struct msghdr msg;
        struct cmsghdr *cmsgtmp;
        u8_t cmsg_buf[CMSG_SPACE(sizeof(struct in_pktinfo))];

        iov.iov_base = rx_buffer;
        iov.iov_len = sizeof(rx_buffer);
        msg.msg_control = cmsg_buf;
        msg.msg_controllen = sizeof(cmsg_buf);
        msg.msg_flags = 0;
        msg.msg_iov = &iov;
        msg.msg_iovlen = 1;
        msg.msg_name = (struct sockaddr *)&source_addr;
        msg.msg_namelen = socklen;

        gpio_pad_select_gpio(LED_PIN);
        gpio_set_direction (LED_PIN,GPIO_MODE_OUTPUT);
        while (1) {
            ESP_LOGI(TAG, "Waiting for data");
            gpio_set_level(LED_PIN,1);
            int len = recvmsg(sock, &msg, 0);
            gpio_set_level(LED_PIN,0);
            // Error occurred during receiving
            if (len < 0) {
                if (errno != 11) {
                  ESP_LOGE(TAG, "recvfrom failed: errno %d", errno);
                }
                break;
            } else {
                // Data received
                // Get the sender's ip address as string
                if (source_addr.ss_family == PF_INET) {
                    inet_ntoa_r(((struct sockaddr_in *)&source_addr)->sin_addr, addr_str, sizeof(addr_str) - 1);
                    for ( cmsgtmp = CMSG_FIRSTHDR(&msg); cmsgtmp != NULL; cmsgtmp = CMSG_NXTHDR(&msg, cmsgtmp) ) {
                        if ( cmsgtmp->cmsg_level == IPPROTO_IP && cmsgtmp->cmsg_type == IP_PKTINFO ) {
                            struct in_pktinfo *pktinfo;
                            pktinfo = (struct in_pktinfo*)CMSG_DATA(cmsgtmp);
                            ESP_LOGI(TAG, "dest ip: %s\n", inet_ntoa(pktinfo->ipi_addr));
                        }
                    }
                } else if (source_addr.ss_family == PF_INET6) {
                    inet6_ntoa_r(((struct sockaddr_in6 *)&source_addr)->sin6_addr, addr_str, sizeof(addr_str) - 1);
                }

                rx_buffer[len] = 0; // Null-terminate whatever we received and treat like a string...
                ESP_LOGI(TAG, "Received %d bytes from %s:", len, addr_str);
                ESP_LOGI(TAG, "%s", rx_buffer);
                if (len == 2) {
                    uint16_t command = (rx_buffer[1] << 8) | (rx_buffer[0]);
                    ESP_LOGI(TAG, "Got command 0x%04X", command);
                    processCommand(command);
                }
                ESP_LOGI(TAG, "Current status is 0x%04X", currentStatus);
                int err = sendto(sock, &currentStatus, 2, 0, (struct sockaddr *)&source_addr, sizeof(source_addr));
                if (err < 0) {
                    ESP_LOGE(TAG, "Error occurred during sending: errno %d", errno);
                    break;
                }
            }
        }

        if (sock != -1) {
            ESP_LOGE(TAG, "Shutting down socket and restarting...");
            shutdown(sock, 0);
            close(sock);
        }
    }
    vTaskDelete(NULL);
}

uint16_t processCommand(uint16_t command) {
    if (command & 0x8000) {
        // Turn on
        ESP_LOGI(TAG, "TURN ON FOR %d SECONDS", command & 0x3FFF);
        currentStatus = command;
    } else if (command & 0x4000) {
        // status
        return currentStatus;
    } else if (!(command & 0x3000)) {
        currentStatus = 0x0000;
        return currentStatus;
    }
    return currentStatus;
}

#define RELAY_PIN 18

void statusLoop(void *pvParams) {
    gpio_pad_select_gpio(RELAY_PIN);
    gpio_set_direction (RELAY_PIN,GPIO_MODE_OUTPUT);
    while (1) {
        if (currentStatus & 0x8000) {
            // we're currently on, decrement the time
            int16_t timeRemaining = currentStatus & 0x3FFF;
            timeRemaining -= 1;
            if (timeRemaining == 0) {
                currentStatus = 0x0000;
            } else {
                currentStatus = 0x8000 | (timeRemaining);
            }
            if (currentStatus & 0x8000) {
                gpio_set_level(RELAY_PIN,1);
            }
        } else {
            gpio_set_level(RELAY_PIN,0);
        }
        vTaskDelay(1000/portTICK_RATE_MS);
    }
}