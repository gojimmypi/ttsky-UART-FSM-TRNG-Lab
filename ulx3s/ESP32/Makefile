PROJECT_NAME := ulx3s_esp32
$(info *************  ulx3s_esp32 *************)

# ------------- BEGIN COMMON SECTION -------------

ifeq ($(strip $(IDF_PATH)),)
  $(error IDF_PATH is not set. Please export it before running make)
endif

# Default compiler flags
CFLAGS   ?=
CXXFLAGS ?=

# The Standard Espressif IDF include:
include $(IDF_PATH)/make/project.mk
