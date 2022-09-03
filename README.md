# Isolation

[![platform_info](https://img.shields.io/pub/v/isolation.svg)](https://pub.dev/packages/isolation)
[![Actions Status](https://github.com/PlugFox/isolation/actions/workflows/checkout.yml/badge.svg)](https://github.com/PlugFox/isolation/actions/workflows/checkout.yml)
[![Coverage](https://codecov.io/gh/PlugFox/isolation/branch/master/graph/badge.svg)](https://codecov.io/gh/PlugFox/isolation)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Linter](https://img.shields.io/badge/style-linter-40c4ff.svg)](https://dart-lang.github.io/linter/lints/)

---

# Overview

The package simplifies the creation and interaction between isolates.
It encapsulates the entire boilerplate, leaving the developer with only transport with an API that looks like two stream controllers.

The package also helps to preserve typing and pass exceptions between isolates.

# Usage

## JSON parser

```dart
import 'dart:async';
import 'dart:convert' show jsonDecode;

import 'package:isolation/isolation.dart';

typedef JsonMap = Map<String, Object?>;

/// Main isolate
void main() => Future<void>(() async {
      // Create a new isolate controller
      final controller = IsolateController<String, JsonMap>(
        _parser,    // Isolate function
        lazy: true, // The isolate will not be created until the first message
      )
       // Add few messages to the isolate:
       ..add('{}')
       ..add('{"field": 123}')
       ..add('{"fizz": "buzz", "value": 2, "undefined": null}');
      // Listen messages from slave isolate
      await controller.stream.take(3).forEach(print);
      // Gracefully closing connection and finally kill slave isolate
      await controller.close(force: false);
    });

/// Slave isolate for parsing JSON, where you can subscribe to the stream
/// from the main isolate and send the result back through the controller.
Future<void> _parser(IsolateController<JsonMap, String> controller) =>
    controller.stream.forEach((json) {
      final result = jsonDecode(json) as Object?;
      (result is JsonMap)
          ? controller.add(result)
          : controller.addError(const FormatException('Invalid JSON'));
    });
```

## Installation

Add the following to your `pubspec.yaml` file to be able to do code generation:

```yaml
dependencies:
  isolation: any
```

Then run:

```shell
dart pub get
```

or

```shell
flutter pub get
```

## Coverage

[![](https://codecov.io/gh/PlugFox/isolation/branch/master/graphs/sunburst.svg)](https://codecov.io/gh/PlugFox/isolation/branch/master)

## Changelog

Refer to the [Changelog](https://github.com/plugfox/isolation/blob/master/CHANGELOG.md) to get all release notes.

## Maintainers

[Plague Fox](https://plugfox.dev)

## License

[MIT](https://github.com/plugfox/isolation/blob/master/LICENSE)
