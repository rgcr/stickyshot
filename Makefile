# StickyShot Makefile
# ~~~~~~~~~~~~~~~~~~~
#
# Build and manage StickyShot macOS application

.PHONY: all build release clean run run-app install uninstall help rebuild open dmg

# Configuration
APP_NAME := StickyShot
BUNDLE_ID := com.stickyshot.app
BUILD_DIR := build
RELEASE_DIR := $(BUILD_DIR)/Release
DEBUG_DIR := $(BUILD_DIR)/Debug
APP_BUNDLE := $(APP_NAME).app
INSTALL_DIR := /Applications

# Version from Info.plist
VERSION := $(shell grep -A1 'CFBundleShortVersionString' StickyShot/Info.plist | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

# Source files
SOURCES := $(shell find StickyShot -name '*.swift')

# Binary paths
DEBUG_BINARY := $(DEBUG_DIR)/$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
RELEASE_BINARY := $(RELEASE_DIR)/$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)

# Default target
all: build


# Build debug version
build: $(DEBUG_BINARY)

$(DEBUG_BINARY): $(SOURCES) StickyShot/Info.plist
	@echo "Building $(APP_NAME) (Debug)..."
	@mkdir -p $(DEBUG_DIR)
	@swiftc \
		-target arm64-apple-macosx12.0 \
		-sdk $(shell xcrun --show-sdk-path) \
		-o $(DEBUG_DIR)/$(APP_NAME) \
		-g \
		-Onone \
		$(SOURCES)
	@$(MAKE) --no-print-directory bundle BUILD_TYPE=Debug
	@echo "Build complete: $(DEBUG_DIR)/$(APP_BUNDLE)"


# Build release version
release: $(RELEASE_BINARY)

$(RELEASE_BINARY): $(SOURCES) StickyShot/Info.plist
	@echo "Building $(APP_NAME) (Release)..."
	@mkdir -p $(RELEASE_DIR)
	@swiftc \
		-target arm64-apple-macosx12.0 \
		-sdk $(shell xcrun --show-sdk-path) \
		-o $(RELEASE_DIR)/$(APP_NAME) \
		-O \
		-whole-module-optimization \
		$(SOURCES)
	@$(MAKE) --no-print-directory bundle BUILD_TYPE=Release
	@echo "Build complete: $(RELEASE_DIR)/$(APP_BUNDLE)"


# Create app bundle structure
bundle:
ifeq ($(BUILD_TYPE),Release)
	$(eval OUT_DIR := $(RELEASE_DIR))
else
	$(eval OUT_DIR := $(DEBUG_DIR))
endif
	@mkdir -p $(OUT_DIR)/$(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(OUT_DIR)/$(APP_BUNDLE)/Contents/Resources
	@mv $(OUT_DIR)/$(APP_NAME) $(OUT_DIR)/$(APP_BUNDLE)/Contents/MacOS/
	@cp StickyShot/Info.plist $(OUT_DIR)/$(APP_BUNDLE)/Contents/
	@sed -i '' 's/$$(EXECUTABLE_NAME)/$(APP_NAME)/g' $(OUT_DIR)/$(APP_BUNDLE)/Contents/Info.plist
	@sed -i '' 's/$$(PRODUCT_BUNDLE_IDENTIFIER)/$(BUNDLE_ID)/g' $(OUT_DIR)/$(APP_BUNDLE)/Contents/Info.plist
	@sed -i '' 's/$$(PRODUCT_NAME)/$(APP_NAME)/g' $(OUT_DIR)/$(APP_BUNDLE)/Contents/Info.plist
	@sed -i '' 's/$$(PRODUCT_BUNDLE_PACKAGE_TYPE)/APPL/g' $(OUT_DIR)/$(APP_BUNDLE)/Contents/Info.plist
	@sed -i '' 's/$$(MACOSX_DEPLOYMENT_TARGET)/12.0/g' $(OUT_DIR)/$(APP_BUNDLE)/Contents/Info.plist
	@sed -i '' 's/$$(DEVELOPMENT_LANGUAGE)/en/g' $(OUT_DIR)/$(APP_BUNDLE)/Contents/Info.plist
	@cp -R StickyShot/Resources/Assets.xcassets $(OUT_DIR)/$(APP_BUNDLE)/Contents/Resources/ 2>/dev/null || true
	@# Sign the app to preserve permissions across rebuilds
	@codesign --force --deep --sign - $(OUT_DIR)/$(APP_BUNDLE) 2>/dev/null || true


# Run debug build (direct binary execution for debugging)
run: build
	@echo "Running $(APP_NAME)..."
	@$(DEBUG_BINARY)


# Run as app bundle (proper macOS app launch)
run-app: build
	@echo "Launching $(APP_NAME).app..."
	@open $(DEBUG_DIR)/$(APP_BUNDLE) --stdout=$(PWD)/stickyshot.log --stderr=$(PWD)/stickyshot.log
	@sleep 1
	@echo "App launched. Logs: tail -f stickyshot.log"
	@echo "Press Ctrl+C to stop watching logs"
	@tail -f stickyshot.log


# Run release build
run-release: release
	@echo "Running $(APP_NAME) (Release)..."
	@$(RELEASE_BINARY)


# Open app bundle (for testing as regular app)
open: build
	@echo "Opening $(APP_NAME).app..."
	@open $(DEBUG_DIR)/$(APP_BUNDLE)


# Install to /Applications
install: release
	@echo "Installing $(APP_NAME) to $(INSTALL_DIR)..."
	@rm -rf $(INSTALL_DIR)/$(APP_BUNDLE)
	@cp -R $(RELEASE_DIR)/$(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)/$(APP_BUNDLE)"


# Uninstall from /Applications
uninstall:
	@echo "Uninstalling $(APP_NAME)..."
	@rm -rf $(INSTALL_DIR)/$(APP_BUNDLE)
	@rm -rf ~/.config/stickyshot
	@echo "Uninstalled $(APP_NAME)"


# Create DMG for distribution
DMG_NAME := $(APP_NAME)-$(VERSION)-macos.dmg

dmg: release
	@echo "Creating DMG..."
	@rm -f $(BUILD_DIR)/$(DMG_NAME)
	@mkdir -p $(BUILD_DIR)/dmg-temp
	@cp -R $(RELEASE_DIR)/$(APP_BUNDLE) $(BUILD_DIR)/dmg-temp/
	@ln -s /Applications $(BUILD_DIR)/dmg-temp/Applications
	@hdiutil create -volname "$(APP_NAME)" -srcfolder $(BUILD_DIR)/dmg-temp -ov -format UDZO $(BUILD_DIR)/$(DMG_NAME)
	@rm -rf $(BUILD_DIR)/dmg-temp
	@echo ""
	@echo "DMG created: $(BUILD_DIR)/$(DMG_NAME)"
	@echo ""
	@echo "SHA256:"
	@shasum -a 256 $(BUILD_DIR)/$(DMG_NAME)
	@echo ""
	@echo "Upload to: https://github.com/rgcr/stickyshot/releases/tag/v$(VERSION)"


# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "Clean complete"


# Force rebuild
rebuild: clean build


# Type check only (fast validation)
check:
	@echo "Type checking..."
	@swiftc -typecheck \
		-target arm64-apple-macosx12.0 \
		-sdk $(shell xcrun --show-sdk-path) \
		$(SOURCES)
	@echo "Type check passed"


# Show help
help:
	@echo "StickyShot Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build        Build debug version (default)"
	@echo "  release      Build release version"
	@echo "  run          Build and run debug binary directly"
	@echo "  run-release  Build and run release binary directly"
	@echo "  open         Build and open app bundle (via Finder)"
	@echo "  install      Install release build to /Applications"
	@echo "  uninstall    Remove from /Applications and config"
	@echo "  clean        Remove build artifacts"
	@echo "  rebuild      Clean and build debug version"
	@echo "  check        Type check sources (fast validation)"
	@echo "  dmg          Create DMG for distribution"
	@echo "  help         Show this help message"
