/*
 * Copyright (c) 2026 gojimmypi
 * SPDX-License-Identifier: Apache-2.0
 *
 * See ATTRIBUTION.md for third-party sources and credits.
 *
 * file: target_pdk.v
 *
 * This file is intended to be included by the top-level project wrapper (project.v) 
 * and used to select the target PDK for the project. 
 */

`default_nettype none

/* Not a TT standard, but we will pick a PDK. Define exactly one: */
`define PDK_TARGET_SKY130
// `define PDK_TARGET_GF180

/* For this project, see TRNG/trng_lab_core.v for conditional include of code based on the PDK. */

`default_nettype wire
