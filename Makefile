#GO_EASY_ON_ME = 1
THEOS_DEVICE_IP = localhost -o StrictHostKeyChecking=no
THEOS_DEVICE_PORT = 2222
ARCHS = arm64 arm64e

TARGET := iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tap2Debug

Tap2Debug_FILES = Tweak.x
Tap2Debug_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
