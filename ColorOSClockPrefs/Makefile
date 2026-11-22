TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ColorOSClockPrefs

ColorOSClockPrefs_FILES = COCRootListController.m
ColorOSClockPrefs_FRAMEWORKS = UIKit
ColorOSClockPrefs_INSTALL_PATH = /Library/PreferenceBundles
ColorOSClockPrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
ColorOSClockPrefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
