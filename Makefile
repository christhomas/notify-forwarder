HOST_OS := $(shell uname -s)
HOST_ARCH := $(shell uname -m)

TARGET_OS ?= $(HOST_OS)
TARGET_ARCH ?= $(HOST_ARCH)

SUPPORTED_TARGETS := darwin_arm64 darwin_x86_64 linux_arm64 linux_x86_64
DEFAULT_TARGETS := $(SUPPORTED_TARGETS)

.PHONY: $(SUPPORTED_TARGETS)

define add_target
.PHONY: $1
$1:
	@echo "Building $1"
	@$(MAKE) --no-print-directory TARGET_OS=$2 TARGET_ARCH=$3 ZIG_ARCH=$(if $(filter arm64,$3),aarch64,x86_64) build
endef

$(eval $(call add_target,darwin_arm64,Darwin,arm64))
$(eval $(call add_target,darwin_x86_64,Darwin,x86_64))
$(eval $(call add_target,linux_arm64,Linux,arm64))
$(eval $(call add_target,linux_x86_64,Linux,x86_64))

ifneq ($(strip $(MAKECMDGOALS)),)
ifneq ($(filter all,$(MAKECMDGOALS)),)
# keep default list
else ifneq ($(filter $(SUPPORTED_TARGETS) build clean,$(MAKECMDGOALS)),)
# explicit targets already provided
else
DEFAULT_TARGETS := build
endif
endif

ifneq ($(filter command environment environment\ override,$(origin TARGET_OS)),)
DEFAULT_TARGETS := build
endif
ifneq ($(filter command environment environment\ override,$(origin TARGET_ARCH)),)
DEFAULT_TARGETS := build
endif

.DEFAULT_GOAL := all

OUT_DIR = _build/$(TARGET_OS)_$(TARGET_ARCH)
OBJ_DIR = $(OUT_DIR)/obj
OUT = $(OUT_DIR)/notify-forwarder

COMMON_SRCS := \
	src/watch_null.cc \
	src/notify_udp.cc \
	src/receive_udp.cc \
	src/inject_utimes.cc \
	src/main.cc \
	src/main_receive.cc \
	src/main_watch.cc

SRCS := $(COMMON_SRCS)
WATCH_PLUGIN_TYPE := NullWatchPlugin
CXXWARNINGS := -Wall -Wextra
PLATFORM_CXXFLAGS :=
PLATFORM_LDFLAGS :=
CXX_TOOLCHAIN := c++

ZIG_ARCH := $(if $(filter arm64,$(TARGET_ARCH)),aarch64,x86_64)

ifeq ($(TARGET_OS),Darwin)
	SRCS += src/watch_fsevents.cc
	WATCH_PLUGIN_TYPE := FSEventsWatchPlugin
	CXXWARNINGS := -Weverything -Wno-c++98-compat -Wno-weak-vtables -Wno-padded
	PLATFORM_CXXFLAGS += -stdlib=libc++
	PLATFORM_LDFLAGS += -framework CoreServices
	SDKROOT ?= $(shell xcrun --sdk macosx --show-sdk-path 2>/dev/null)
	ifneq ($(SDKROOT),)
		PLATFORM_CXXFLAGS += -isysroot $(SDKROOT)
		PLATFORM_LDFLAGS += -isysroot $(SDKROOT)
	endif
	ARCHFLAG := $(if $(filter arm64,$(TARGET_ARCH)),-arch arm64,-arch x86_64)
	PLATFORM_CXXFLAGS += $(ARCHFLAG)
	PLATFORM_LDFLAGS += $(ARCHFLAG)
	CXX_TOOLCHAIN := xcrun --sdk macosx clang++
else ifeq ($(TARGET_OS),Linux)
	SRCS += src/watch_inotify.cc
	WATCH_PLUGIN_TYPE := InotifyWatchPlugin
	CXX_TOOLCHAIN := zig c++ -target $(ZIG_ARCH)-linux-gnu
else
	$(error Unsupported TARGET_OS '$(TARGET_OS)')
endif

CXXFLAGS = -MD -g -O0 -std=c++17 $(CXXWARNINGS) -DWATCH_PLUGIN_TYPE=$(WATCH_PLUGIN_TYPE) $(PLATFORM_CXXFLAGS) $(EXTRA_CXXFLAGS)

ifeq ($(origin CXX), default)
CXX := $(CXX_TOOLCHAIN)
else
CXX ?= $(CXX_TOOLCHAIN)
endif

OBJECTS = $(patsubst src/%.cc,$(OBJ_DIR)/%.o,$(SRCS))
DEPFILES = $(OBJECTS:.o=.d)

all: $(DEFAULT_TARGETS)

build: $(OUT)

$(OUT): $(OBJECTS)
	@mkdir -p $(dir $@)
	$(CXX) $(CFLAGS) $(LDFLAGS) $(PLATFORM_LDFLAGS) -o $@ $(OBJECTS)
$(OBJ_DIR):
	@mkdir -p $@

$(OBJ_DIR)/%.o: src/%.cc | $(OBJ_DIR)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf _build

.PHONY: all clean build $(SUPPORTED_TARGETS)

-include $(DEPFILES)
