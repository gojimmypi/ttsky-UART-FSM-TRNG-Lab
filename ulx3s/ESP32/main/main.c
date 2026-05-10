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
// #include "main.h"

/* ESP-IDF */
#include "sdkconfig.h"
#include <esp_log.h>

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include "sdkconfig.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_chip_info.h"
#include "esp_flash.h" 
#include "esp_system.h"
#include "driver/spi_master.h"
#include "esp_err.h"

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


/*
 * Set these to match the ESP32 pins wired to the ULX3S FPGA.
 * Avoid SPI1 unless you specifically know you need it.
 */
#define ULX3S_SPI_HOST      SPI2_HOST

#if 0
    #define PIN_NUM_MISO        19
    #define PIN_NUM_MOSI        23
    #define PIN_NUM_CLK         18
    #define PIN_NUM_CS          5
#endif

#define PIN_NUM_MISO        2
#define PIN_NUM_MOSI        15
#define PIN_NUM_CLK         14
#define PIN_NUM_CS          13

#define SPI_CLOCK_HZ        1000000

static const char* const TAG = "main";


static spi_device_handle_t ulx3s_spi;

static esp_err_t ulx3s_spi_init(void)
{
    esp_err_t ret;

    spi_bus_config_t buscfg;
    spi_device_interface_config_t devcfg;

    memset(&buscfg, 0, sizeof(buscfg));
    memset(&devcfg, 0, sizeof(devcfg));

    buscfg.miso_io_num = PIN_NUM_MISO;
    buscfg.mosi_io_num = PIN_NUM_MOSI;
    buscfg.sclk_io_num = PIN_NUM_CLK;
    buscfg.quadwp_io_num = -1;
    buscfg.quadhd_io_num = -1;
    buscfg.max_transfer_sz = 32;

    devcfg.clock_speed_hz = SPI_CLOCK_HZ;
    devcfg.mode = 0;
    devcfg.spics_io_num = PIN_NUM_CS;
    devcfg.queue_size = 1;

    ret = spi_bus_initialize(ULX3S_SPI_HOST, &buscfg, SPI_DMA_DISABLED);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "spi_bus_initialize failed: %s", esp_err_to_name(ret));
        return ret;
    }

    ret = spi_bus_add_device(ULX3S_SPI_HOST, &devcfg, &ulx3s_spi);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "spi_bus_add_device failed: %s", esp_err_to_name(ret));
        return ret;
    }

    return ESP_OK;
}

static esp_err_t ulx3s_spi_transfer(
    const uint8_t *tx_buf,
    uint8_t *rx_buf,
    size_t len)
{
    spi_transaction_t trans;
    esp_err_t ret;

    memset(&trans, 0, sizeof(trans));

    trans.length = len * 8U;
    trans.tx_buffer = tx_buf;
    trans.rx_buffer = rx_buf;

    ret = spi_device_transmit(ulx3s_spi, &trans);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "spi_device_transmit failed: %s", esp_err_to_name(ret));
    }

    return ret;
}

static void ulx3s_spi_test_once(void)
{
    esp_err_t ret;

    /*
     * Byte 0 is command.
     * Byte 1 is payload or dummy clocks for readback.
     *
     * With many simple SPI slaves, rx[0] is old/stale.
     * The useful response often appears in rx[1] or later.
     */
    uint8_t tx_buf[2];
    uint8_t rx_buf[2];

    tx_buf[0] = 0x52U;  /* Example command, ASCII 'R' */
    tx_buf[1] = 0x00U;  /* Dummy byte to clock response */

    rx_buf[0] = 0x00U;
    rx_buf[1] = 0x00U;

    ret = ulx3s_spi_transfer(tx_buf, rx_buf, sizeof(tx_buf));
    if (ret != ESP_OK) {
        return;
    }

    ESP_LOGI(TAG, "tx: %02X %02X  rx: %02X %02X",
             tx_buf[0], tx_buf[1],
             rx_buf[0], rx_buf[1]);
}

/* entry point */
void app_main(void)
{
    esp_err_t ret;
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

    ret = ulx3s_spi_init();
    if (ret != ESP_OK) {
        return;
    }

    while (1) {
        ulx3s_spi_test_once();
        vTaskDelay(pdMS_TO_TICKS(1000));
    }

    for (int i = 10; i >= 0; i--) {
        printf("Restarting in %d seconds...\n", i);
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();

}
