/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: main.h
 *
 * ESP32 main app
 * 
 ***********************************************************************************************
 *                                NOTICE - IMPORTANT
 ***********************************************************************************************
 * The ESP32 on the ULX3S sits behind the FPGA! When using the serial port for programming, the
 * FPGA ** MUST ** be configured in passthru mode. See top_ulx3s.v file. Something like:
 * 
 *       assign wifi_en    = btn[0];
 *       assign wifi_gpio0 = btn[1];
 *
 * If ESP32_BOOT_CONTROL_ENABLED is defined, BTN0 controls wifi_en and BTN1 controls wifi_gpio0
 *
 * To RESET the ESP32 and start the running program in flash:
 * 
 *    Hold btn[1]
 *    Tap btn[0]
 *    Release btn[1]
 *
 * To PROGRAM the ESP32 in flash:
 * 
 *    Hold btn[0]
 *      (begin flash upload)
 *    Release btn[0] when "Connecting..." is observed.
 *
 * Should then see something like:
 *
 *   Chip is ESP32-D0WDQ6 (revision v1.0)
 *   Features: WiFi, BT, Dual Core, 240MHz, VRef calibration in efuse, Coding Scheme None
 *   Crystal is 40MHz
 *   Uploading stub...
 *   Running stub...
 *   Stub running...
 *   Changing baud rate to 460800
 *   Changed.
 */

/* ESP-IDF */
#include "sdkconfig.h"
#include <esp_log.h>

#include <stdio.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_system.h"

/* Hardware; include after other libraries,
 * particularly after freeRTOS from settings.h */
// #include <driver/uart.h>


#define THIS_MONITOR_UART_RX_BUFFER_SIZE 200

#ifdef CONFIG_ESP8266_XTAL_FREQ_26
    /* 26MHz crystal: 74880 bps */
    #define THIS_MONITOR_UART_BAUD_DATE 74880
#else
    /* 40MHz crystal: 115200 bps */
    #define THIS_MONITOR_UART_BAUD_DATE 115200
#endif

// #include "main.h"

static const char* const TAG = "main";

/* entry point */
void app_main(void)
{
    int stack_start = 0;

    ESP_LOGI(TAG, "------------------- ULX3S ESP32 Example ----------------");
    ESP_LOGI(TAG, "--------------------------------------------------------");
    ESP_LOGI(TAG, "--------------------------------------------------------");
    ESP_LOGI(TAG, "---------------------- BEGIN MAIN ----------------------");
    ESP_LOGI(TAG, "--------------------------------------------------------");
    ESP_LOGI(TAG, "--------------------------------------------------------");
    ESP_LOGI(TAG, "Stack Start: 0x%x", stack_start);

    /* all platforms: stack high water mark check */
    ESP_LOGI(TAG, "Stack HWM: %d\n", uxTaskGetStackHighWaterMark(NULL));


    printf("Hello world 2!\n");

    /* Print chip information */
    esp_chip_info_t chip_info;
    uint32_t flash_size;
    esp_chip_info(&chip_info);
    printf("This is %s chip with %d CPU core(s), %s%s%s%s, ",
        CONFIG_IDF_TARGET,
        chip_info.cores,
        (chip_info.features & CHIP_FEATURE_WIFI_BGN) ? "WiFi/" : "",
        (chip_info.features & CHIP_FEATURE_BT) ? "BT" : "",
        (chip_info.features & CHIP_FEATURE_BLE) ? "BLE" : "",
        (chip_info.features & CHIP_FEATURE_IEEE802154) ? ", 802.15.4 (Zigbee/Thread)" : "");

    unsigned major_rev = chip_info.revision / 100;
    unsigned minor_rev = chip_info.revision % 100;
    printf("silicon revision v%d.%d, ", major_rev, minor_rev);
    if (esp_flash_get_size(NULL, &flash_size) != ESP_OK) {
        printf("Get flash size failed");
        return;
    }

    printf("%" PRIu32 "MB %s flash\n", flash_size / (uint32_t)(1024 * 1024),
        (chip_info.features & CHIP_FEATURE_EMB_FLASH) ? "embedded" : "external");

    printf("Minimum free heap size: %" PRIu32 " bytes\n", esp_get_minimum_free_heap_size());

    for (int i = 10; i >= 0; i--) {
        printf("Restarting in %d seconds...\n", i);
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();

}
