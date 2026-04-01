ARCHS = arm64
TARGET = iphone:clang:15.6:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = IPodClassic

IPodClassic_FILES = main.m AppDelegate.m RootViewController.m ClickWheelView.m NowPlayingViewController.m MenuViewController.m TrackListViewController.m SettingsViewController.m CoverFlowViewController.m IPDMenuCell.m IPDArtworkCache.m IPDMediaLibrary.m
IPodClassic_FRAMEWORKS = UIKit Foundation MediaPlayer CoreGraphics QuartzCore AudioToolbox
IPodClassic_CODESIGN_FLAGS = -Sentitlements.plist
IPodClassic_CFLAGS = -fobjc-arc
IPodClassic_INFOPLIST_FILE = Info.plist

include $(THEOS_MAKE_PATH)/application.mk
