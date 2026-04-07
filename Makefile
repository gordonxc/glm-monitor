APP_NAME    := GLMMonitor
APP_BUNDLE  := build/$(APP_NAME).app
EXECUTABLE  := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
BUILD_DIR   := .build/release
SWIFTC      := swift build -c release

.PHONY: build run clean

build: $(APP_BUNDLE)

$(APP_BUNDLE): $(BUILD_DIR)/GLMMonitor
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/GLMMonitor $(EXECUTABLE)
	cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	cp Sources/GLMMonitor/AppIcon.png $(APP_BUNDLE)/Contents/Resources/AppIcon.png
	@echo "Built $(APP_BUNDLE)"

$(BUILD_DIR)/GLMMonitor: Sources/GLMMonitor/**/*.swift Package.swift
	$(SWIFTC)

run: build
	open $(APP_BUNDLE)

clean:
	rm -rf .build build
