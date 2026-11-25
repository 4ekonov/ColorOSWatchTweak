TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

# Для rootless (Dopamine / palera1n rootless) собирай с:
#   make package THEOS_PACKAGE_SCHEME=rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ColorOSClock

ColorOSClock_FILES = Tweak.xm COCClockView.m
ColorOSClock_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
ColorOSClock_FRAMEWORKS = UIKit CoreText QuartzCore

SUBPROJECTS += ColorOSClockPrefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
