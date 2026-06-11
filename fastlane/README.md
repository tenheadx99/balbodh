fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_signed

```sh
[bundle exec] fastlane android build_signed
```

Build signed release AAB

### android build_signed_apk

```sh
[bundle exec] fastlane android build_signed_apk
```

Build signed APK

### android sync_text_metadata

```sh
[bundle exec] fastlane android sync_text_metadata
```

Sync text metadata from Metadata.json

### android sync_screenshots

```sh
[bundle exec] fastlane android sync_screenshots
```

Sync manually placed screenshots into metadata folders

### android sync_metadata

```sh
[bundle exec] fastlane android sync_metadata
```

Sync all metadata (text and screenshots)

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Deploy to production: build + upload bundle + update listing & screenshots

### android deploy_all

```sh
[bundle exec] fastlane android deploy_all
```

Full deploy to production: build + upload + content rating

### android submit_content_rating

```sh
[bundle exec] fastlane android submit_content_rating
```

Submit content rating questionnaire

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
