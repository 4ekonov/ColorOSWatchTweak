TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

# Для rootless (Dopamine / palera1n rootless) собирай с:
#   make package THEOS_PACKAGE_SCHEME=rootless

include $(THEOS)/makefiles/common.mk

# GitHub при загрузке файлов через браузер теряет права на запуск — выставляем их сами,
# иначе dpkg отклонит скрипт postinst (респринг после установки).
_COC_FIXPERM := $(shell chmod 0755 layout/DEBIAN/postinst 2>/dev/null)

# В репозитории могут оставаться чужие файлы от других проектов (например, ColorOSCC.plist от другого твика —
# из-за него dpkg отказывается ставить пакет). В layout/ оставляем только то, что принадлежит этому твику.
_COC_CLEAN := $(shell find layout -type f ! -path 'layout/DEBIAN/postinst' ! -path 'layout/Library/PreferenceLoader/Preferences/ColorOSClock.plist' -delete 2>/dev/null)

TWEAK_NAME = ColorOSClock

ColorOSClock_FILES = Tweak.xm COCClockView.m
ColorOSClock_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
ColorOSClock_FRAMEWORKS = UIKit CoreText QuartzCore

SUBPROJECTS += ColorOSClockPrefs

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
