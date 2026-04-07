APP_NAME    := GLMMonitor
APP_BUNDLE  := build/$(APP_NAME).app
EXECUTABLE  := $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
BUILD_DIR   := .build/release
SWIFTC      := swift build -c release
FRAMEWORKS  := $(APP_BUNDLE)/Contents/Frameworks

# Find Sparkle framework in SPM artifacts
SPARKLE_SRC := $(shell find .build -path "*/release/Sparkle.framework" -type d 2>/dev/null | head -1)

.PHONY: build run clean

build: $(APP_BUNDLE)

$(APP_BUNDLE): $(BUILD_DIR)/GLMMonitor
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/GLMMonitor $(EXECUTABLE)
	cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	cp Sources/GLMMonitor/AppIcon.png $(APP_BUNDLE)/Contents/Resources/AppIcon.png
	@mkdir -p $(FRAMEWORKS)
	@if [ -n "$(SPARKLE_SRC)" ]; then \
		cp -R "$(SPARKLE_SRC)" $(FRAMEWORKS)/; \
		install_name_tool -change @rpath/Sparkle.framework/Versions/B/Sparkle \
			@executable_path/../Frameworks/Sparkle.framework/Versions/B/Sparkle \
			$(EXECUTABLE); \
		echo "Embedded Sparkle.framework"; \
	else \
		echo "Warning: Sparkle.framework not found in build artifacts"; \
	fi
	@echo "Built $(APP_BUNDLE)"

$(BUILD_DIR)/GLMMonitor: Sources/GLMMonitor/**/*.swift Package.swift
	$(SWIFTC)

run: build
	open $(APP_BUNDLE)

clean:
	rm -rf .build build
