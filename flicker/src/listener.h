#include <lwip/netdb.h>
#include "esp_netif.h"

// This is ugly, but this is our GLOBAL status, no one should write to this outside of listener.h
uint16_t getCurrentStatus();
void udp_server_task(void *pvParameters);
void statusLoop(void *pvParams);