#include <driver/gpio.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "nvs_flash.h"
#include "esp_log.h"
#include "esp_err.h"
#include "wifi.h"
#include "listener.h"

void app_main() {
    //Initialize NVS
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
      ESP_ERROR_CHECK(nvs_flash_erase());
      ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    ESP_ERROR_CHECK(esp_netif_init());

    ESP_LOGI("FLICKER", "ESP_WIFI_MODE_STA");
    wifi_init_sta();
    xTaskCreate(&udp_server_task, "udp_server", 4096, (void*)AF_INET, 5, NULL);
    xTaskCreate(&statusLoop,"STATUS_LOOP",4096,NULL,5,NULL);
}