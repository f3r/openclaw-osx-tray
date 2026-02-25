APP_NAME = OpenClaw.app
BUILD_DIR = .build
BUNDLE_DIR = $(BUILD_DIR)/$(APP_NAME)
BINARY_NAME = OpenClawTray
RELEASE_BINARY = $(BUILD_DIR)/release/$(BINARY_NAME)

.PHONY: build run clean bundle

build: bundle

$(RELEASE_BINARY):
	swift build -c release

bundle: $(RELEASE_BINARY)
	mkdir -p "$(BUNDLE_DIR)/Contents/MacOS"
	cp $(RELEASE_BINARY) "$(BUNDLE_DIR)/Contents/MacOS/$(BINARY_NAME)"
	cp Resources/Info.plist "$(BUNDLE_DIR)/Contents/"

run: bundle
	open "$(BUNDLE_DIR)"

install: bundle
	mkdir -p ~/Applications
	rm -rf ~/Applications/$(APP_NAME)
	cp -R "$(BUNDLE_DIR)" ~/Applications/$(APP_NAME)
	ln -sf ~/Applications/$(APP_NAME) /Applications/$(APP_NAME)
	@echo "Installed to ~/Applications/$(APP_NAME)"

uninstall:
	rm -rf ~/Applications/$(APP_NAME)
	rm -f /Applications/$(APP_NAME)

clean:
	swift package clean
	rm -rf "$(BUNDLE_DIR)"
