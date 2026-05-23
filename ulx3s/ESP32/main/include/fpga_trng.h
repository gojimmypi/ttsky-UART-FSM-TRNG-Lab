/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: ./ulx3s/ESP32/main/include/fpga_trng.h
 *
 * ESP32 ulx3s_spi_lib FPGA SPI library
 *
 */
#ifndef FPGA_TRNG_H
#define FPGA_TRNG_H

#include <stddef.h>
#include <stdint.h>

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

#define FPGA_TRNG_REG_CTRL       0x00U
#define FPGA_TRNG_REG_SRC        0x01U
#define FPGA_TRNG_REG_DIV        0x02U
#define FPGA_TRNG_REG_MODE       0x03U
#define FPGA_TRNG_REG_OSCEN      0x04U
#define FPGA_TRNG_REG_STATUS     0x05U
#define FPGA_TRNG_REG_RAWLO      0x06U
#define FPGA_TRNG_REG_RAWHI      0x07U

#define FPGA_TRNG_CTRL_NONE         0x00U
#define FPGA_TRNG_CTRL_ENABLE       0x01U
#define FPGA_TRNG_CTRL_SINGLE_STEP  0x02U
#define FPGA_TRNG_CTRL_RESET        0x04U

#define FPGA_TRNG_BITS_PER_SAMPLE        16U
#define FPGA_TRNG_LIVE_SAMPLE_DELAY_MS   10U

#define FPGA_TRNG_DEFAULT_DIV       0x10U
#define FPGA_TRNG_DEFAULT_MODE      0x00U
#define FPGA_TRNG_DEFAULT_OSCEN     0x01U

typedef enum fpga_trng_source {
    FPGA_TRNG_SOURCE_LFSR_TEST = 0U,
    FPGA_TRNG_SOURCE_RO0       = 1U,
    FPGA_TRNG_SOURCE_ROX       = 2U,
    FPGA_TRNG_SOURCE_MIX       = 3U
} fpga_trng_source_t;

typedef struct fpga_trng_sample {
    uint8_t status;
    uint16_t raw;
} fpga_trng_sample_t;

esp_err_t fpga_trng_init_defaults(void);

esp_err_t fpga_trng_configure_lfsr_test_mode(void);
esp_err_t fpga_trng_pulse_single_step(void);
esp_err_t fpga_trng_read_lfsr_sample(fpga_trng_sample_t *sample);

esp_err_t fpga_trng_configure_live(
    fpga_trng_source_t source,
    uint8_t divider,
    uint8_t oscillator_mask);

esp_err_t fpga_trng_read_live_sample(fpga_trng_sample_t *sample);
esp_err_t fpga_trng_read_live_raw(uint16_t *raw);
esp_err_t fpga_trng_fill_live(uint8_t *buffer, size_t length);

esp_err_t fpga_trng_read_sample(fpga_trng_sample_t *sample);
esp_err_t fpga_trng_read_raw(uint16_t *raw);
esp_err_t fpga_trng_fill(uint8_t *buffer, size_t length);

#ifdef __cplusplus
}
#endif

#endif /* FPGA_TRNG_H */
