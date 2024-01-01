<img src="https://raw.githubusercontent.com/refena/refena/main/resources/main-logo-2048.webp" height="100" alt="Logo" />

[![pub package](https://img.shields.io/pub/v/refena_sentry.svg)](https://pub.dev/packages/refena_sentry)
![ci](https://github.com/refena/refena/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Sentry integration for Refena.

![sentry](https://raw.githubusercontent.com/refena/refena/main/resources/sentry.webp)

## Setup

Add the following dependencies to your `pubspec.yaml`:

```yaml
# pubspec.yaml
dependencies:
  refena_sentry: <version>
```

Add the `RefenaSentryObserver`:

```dart
void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://example@sentry.io/example';
    },
    appRunner: () {
      runApp(
        RefenaScope(
          observers: [
            RefenaSentryObserver(), // <-- Add the observer
          ],
          child: MyApp(),
        ),
      );
    },
  );
}
```
