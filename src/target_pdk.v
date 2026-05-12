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

`default_nettype wire
