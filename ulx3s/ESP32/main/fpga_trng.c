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

static const char *TAG = "fpga_trng";

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

esp_err_t fpga_trng_read_raw(uint16_t *raw)
{
    esp_err_t err;
    fpga_trng_sample_t sample;

    if (raw == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    sample.status = 0U;
    sample.raw = 0U;

    err = fpga_trng_read_sample(&sample);
    ESP_RETURN_ON_ERROR(err, TAG, "failed to read TRNG sample");

    *raw = sample.raw;

    return ESP_OK;
}

esp_err_t fpga_trng_fill(uint8_t *buffer, size_t length)
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

        err = fpga_trng_read_raw(&raw);
        ESP_RETURN_ON_ERROR(err, TAG, "failed to read TRNG raw value");

        buffer[index] = (uint8_t)(raw & 0xFFU);
        index++;

        if (index < length) {
            buffer[index] = (uint8_t)((raw >> 8U) & 0xFFU);
            index++;
        }
    }

    return ESP_OK;
}