APP_NAME = SoundSwitcher
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0")
RELEASE_ZIP = $(APP_NAME)-$(VERSION)-arm64.zip

build:
	swift build -c release

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Sources/SoundSwitcher/Info.plist $(APP_BUNDLE)/Contents/
	codesign --force --sign - $(APP_BUNDLE)

release: bundle
	rm -f $(RELEASE_ZIP)
	zip -r $(RELEASE_ZIP) $(APP_BUNDLE)
	@echo ""
	@echo "✅ Release ready: $(RELEASE_ZIP)"
	@echo "   Upload to: https://github.com/YOUR_USER/SoundSwitcher/releases/new"

install: bundle
	cp -r $(APP_BUNDLE) /Applications/
	open /Applications/$(APP_BUNDLE)

run: bundle
	open $(APP_BUNDLE)

clean:
	rm -rf .build $(APP_BUNDLE) *.zip
