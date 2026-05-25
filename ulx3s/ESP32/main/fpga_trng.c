/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: ./ulx3s/ESP32/main/fpga_trng.c
 *
 * ESP32 ulx3s_spi_lib FPGA SPI library
 *
 */

#include "fpga_trng.h"

#include "esp_check.h"
#include "esp_log.h"
#include "ulx3s_spi_lib.h"

/* RTOS needed for vTaskDelay */
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

static const char *TAG = "fpga_trng";

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_init_defaults(void)
{
    esp_err_t err;

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_DIV, FPGA_TRNG_DEFAULT_DIV);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG divider");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_MODE, FPGA_TRNG_DEFAULT_MODE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG mode");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_OSCEN, FPGA_TRNG_DEFAULT_OSCEN);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG oscillator enable");

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_configure_lfsr_test_mode(void)
{
    esp_err_t err;

    /* Disable sampling and clear single-step/reset control bits. */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_NONE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to clear TRNG control register");

    /* Pulse TRNG internal reset through reg_ctrl[2]. */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_RESET);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to assert TRNG reset");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_NONE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to release TRNG reset");

    /* Source 0 is the deterministic LFSR test source. */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_SRC, (uint8_t)FPGA_TRNG_SOURCE_LFSR_TEST);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to select TRNG LFSR source");

    /* Keep this test purely digital and deterministic. */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_OSCEN, 0x00U);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to disable TRNG oscillators");

    /* Match the UART regression test setup. */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_DIV, 0x01U);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG divider");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_MODE, 0x00U);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG mode");

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_pulse_single_step(void)
{
    esp_err_t err;

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_SINGLE_STEP);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to assert TRNG single-step bit");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_NONE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to release TRNG single-step bit");

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_read_lfsr_sample(fpga_trng_sample_t *sample)
{
    esp_err_t err;
    unsigned int bit_index;

    if (sample == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    /* Keep free-running sampling disabled while building a deterministic sample. */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_NONE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to disable TRNG sampling");

    for (bit_index = 0U; bit_index < FPGA_TRNG_BITS_PER_SAMPLE; bit_index++) {
        err = fpga_trng_pulse_single_step();
        ESP_RETURN_ON_ERROR(err, TAG, "failed to pulse TRNG single-step bit");
    }

    err = fpga_trng_read_sample(sample);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to read stepped TRNG sample");

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_read_sample(fpga_trng_sample_t *sample)
{
    esp_err_t err;
    uint8_t status;
    uint8_t rawlo;
    uint8_t rawhi;
    uint16_t raw;

    if (sample == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    status = 0U;
    rawlo = 0U;
    rawhi = 0U;
    raw = 0U;

    err = ulx3s_spi_read_reg(FPGA_TRNG_REG_STATUS, &status);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to read TRNG status");

    err = ulx3s_spi_read_reg(FPGA_TRNG_REG_RAWLO, &rawlo);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to read TRNG raw low byte");

    err = ulx3s_spi_read_reg(FPGA_TRNG_REG_RAWHI, &rawhi);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to read TRNG raw high byte");

    raw = (uint16_t)rawhi;
    raw <<= 8U;
    raw |= (uint16_t)rawlo;

    sample->status = status;
    sample->raw = raw;

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_read_raw(uint16_t *raw)
{
    return fpga_trng_read_live_raw(raw);
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_configure_live(
    fpga_trng_source_t source,
    uint8_t divider,
    uint8_t oscillator_mask)
{
    esp_err_t err;

    if ((source < FPGA_TRNG_SOURCE_RO0) || (source > FPGA_TRNG_SOURCE_MIX)) {
        return ESP_ERR_INVALID_ARG;
    }

    /*
     * Live mode uses the FPGA sampler instead of deterministic single-step.
     * Clear reg_ctrl first so stale enable/step/reset bits do not leak in.
     */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_NONE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to clear TRNG control register");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_SRC, (uint8_t)source);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG source");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_DIV, divider);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG divider");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_MODE, 0x00U);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG mode");

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_OSCEN, oscillator_mask);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to write TRNG oscillator mask");

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_read_live_sample(fpga_trng_sample_t *sample)
{
    esp_err_t err;

    if (sample == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    /*
     * This matches the UART live-sample pattern:
     * enable sampling, let the FPGA run, freeze sampling, then read R6/R7.
     */
    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_ENABLE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to enable TRNG sampling");

    vTaskDelay(pdMS_TO_TICKS(FPGA_TRNG_LIVE_SAMPLE_DELAY_MS));

    err = ulx3s_spi_write_reg(FPGA_TRNG_REG_CTRL, FPGA_TRNG_CTRL_NONE);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to freeze TRNG sampling");

    err = fpga_trng_read_sample(sample);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to read live TRNG sample");

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_read_live_raw(uint16_t *raw)
{
    esp_err_t err;
    fpga_trng_sample_t sample;

    if (raw == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    sample.status = 0U;
    sample.raw = 0U;

    err = fpga_trng_read_live_sample(&sample);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to read live TRNG sample");

    *raw = sample.raw;

    return ESP_OK;
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_fill(uint8_t *buffer, size_t length)
{
    return fpga_trng_fill_live(buffer, length);
}

/******************************************************************************
 *
 ******************************************************************************/
esp_err_t fpga_trng_fill_live(uint8_t *buffer, size_t length)
{
    esp_err_t err;
    size_t index;

    if ((buffer == NULL) && (length != 0U)) {
        return ESP_ERR_INVALID_ARG;
    }

    index = 0U;

    while (index < length) {
        uint16_t raw;

        raw = 0U;

        err = fpga_trng_read_live_raw(&raw);
        ESP_RETURN_ON_ERROR(err, TAG, "failed to read live TRNG raw value");

        buffer[index] = (uint8_t)(raw & 0xFFU);
        index++;

        if (index < length) {
            buffer[index] = (uint8_t)((raw >> 8U) & 0xFFU);
            index++;
        }
    }

    return ESP_OK;
}
