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
#include "main.h"

#include "ulx3s_spi_lib.h"
#include "fpga_trng.h"

/* ESP-IDF */
#include "sdkconfig.h"
#include <esp_log.h>

#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <sdkconfig.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_chip_info.h>
#include <esp_flash.h>
#include <esp_system.h>
#include <esp_err.h>

/* Hardware; include after other libraries,
 * particularly after freeRTOS from settings.h */
// #include <driver/uart.h>

#define THIS_MONITOR_UART_RX_BUFFER_SIZE 200
#define TRNG_DEMO_SAMPLE_COUNT 8

#ifdef CONFIG_ESP8266_XTAL_FREQ_26
    /* 26MHz crystal: 74880 bps */
    #define THIS_MONITOR_UART_BAUD_DATE 74880
#else
    /* 40MHz crystal: 115200 bps */
    #define THIS_MONITOR_UART_BAUD_DATE 115200
#endif

static const char* const TAG = "main";

static esp_err_t trng_lfsr_demo(void)
{
    esp_err_t err;
    fpga_trng_sample_t sample;
    int i;

    sample.status = 0U;
    sample.raw = 0U;

    ESP_LOGI(TAG, "TRNG deterministic LFSR test");

    err = fpga_trng_configure_lfsr_test_mode();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "fpga_trng_configure_lfsr_test_mode failed: %s", esp_err_to_name(err));
        return err;
    }

    for (i = 0; i < TRNG_DEMO_SAMPLE_COUNT; i++) {
        err = fpga_trng_read_lfsr_sample(&sample);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "fpga_trng_read_lfsr_sample failed: %s", esp_err_to_name(err));
            return err;
        }

        ESP_LOGI(TAG, "lfsr test sample %02d: raw=0x%04X status=0x%02X",
                 i,
                 sample.raw,
                 sample.status);
    }

    return ESP_OK;
} /* trng_lfsr_demo */

static esp_err_t trng_live_source_demo(
    const char *name,
    fpga_trng_source_t source,
    uint8_t oscillator_mask)
{
    esp_err_t err;
    fpga_trng_sample_t sample;
    int i;

    sample.status = 0U;
    sample.raw = 0U;

    ESP_LOGI(TAG, "TRNG live source test: %s", name);

    err = fpga_trng_configure_live(source, 0x01U, oscillator_mask);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "fpga_trng_configure_live failed: %s", esp_err_to_name(err));
        return err;
    }

    for (i = 0; i < TRNG_DEMO_SAMPLE_COUNT; i++) {
        err = fpga_trng_read_live_sample(&sample);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "fpga_trng_read_live_sample failed: %s", esp_err_to_name(err));
            return err;
        }

        ESP_LOGI(TAG, "%s sample %02d: raw=0x%04X status=0x%02X",
                 name,
                 i,
                 sample.raw,
                 sample.status);
    }

    return ESP_OK;
} /* trng_live_source_demo */

static esp_err_t trng_demo(void)
{
    esp_err_t err;

    err = trng_lfsr_demo();
    if (err != ESP_OK) {
        return err;
    }

    err = trng_live_source_demo("S1 RO0/fallback", FPGA_TRNG_SOURCE_RO0, 0x01U);
    if (err != ESP_OK) {
        return err;
    }

    err = trng_live_source_demo("S2 ROX/fallback", FPGA_TRNG_SOURCE_ROX, 0xFFU);
    if (err != ESP_OK) {
        return err;
    }

    err = trng_live_source_demo("S3 MIX/fallback", FPGA_TRNG_SOURCE_MIX, 0xFFU);
    if (err != ESP_OK) {
        return err;
    }

    return ESP_OK;
} /* trng_demo */

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


    printf("Hello world 3!\n");

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

#if (ULX3S_SPI_WRITE_MODE == ULX3S_SPI_WRITE_MODE_BOOT_CONFIG_ONCE)
    ESP_LOGI(TAG, "SPI write mode: boot config once");
    ulx3s_spi_apply_default_config_once();
#elif (ULX3S_SPI_WRITE_MODE == ULX3S_SPI_WRITE_MODE_SELF_TEST_ONCE)
    ESP_LOGI(TAG, "SPI write mode: self-test once");
    ulx3s_spi_self_test_once();
#else
    ESP_LOGI(TAG, "SPI write mode: monitor only");
#endif

    vTaskDelay(pdMS_TO_TICKS(100));

    ret = trng_demo();
    if (ret != ESP_OK) {
        return;
    }

    ret = ulx3s_spi_reset_config_registers();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "ulx3s_spi_reset_config_registers failed: %s", esp_err_to_name(ret));
        return;
    }

    ret = ulx3s_spi_dump_regs();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "ulx3s_spi_dump_regs failed: %s", esp_err_to_name(ret));
        return;
    }

    while (1) {
        ret = ulx3s_spi_monitor_once();
        if (ret != ESP_OK) {
            ESP_LOGE(TAG, "ulx3s_spi_monitor_once failed: %s", esp_err_to_name(ret));
        }

        vTaskDelay(pdMS_TO_TICKS(ULX3S_SPI_MONITOR_POLL_DELAY_MS));
    }

    /* disabled code follows */
    for (int i = 10; i >= 0; i--) {
        printf("Restarting in %d seconds...\n", i);
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();

}
