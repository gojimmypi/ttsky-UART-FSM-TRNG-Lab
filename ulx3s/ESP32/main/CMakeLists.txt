idf_component_register(
                       SRCS "main.c" ulx3s_spi_lib.c fpga_trng.c
                       PRIV_REQUIRES spi_flash esp_driver_spi
                       INCLUDE_DIRS "./include")
