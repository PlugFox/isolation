// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert' show jsonDecode;

import 'package:isolation/isolation.dart';

typedef JsonMap = Map<String, Object?>;

void main() => Future<void>(() async {
      final controller = IsolateController<String, JsonMap>(
        _callback,
        lazy: true,
      )
        ..add('{}')
        ..add('{"field": 123}')
        ..add('{"fizz": "buzz", "value": 2, "undefined": null}');
      await controller.stream.take(3).forEach(print);
      await controller.close(force: false);
    });

Future<void> _callback(IsolateController<JsonMap, String> controller) =>
    controller.stream.forEach((json) {
      final result = jsonDecode(json) as Object?;
      (result is JsonMap)
          ? controller.add(result)
          : controller.addError(const FormatException('Invalid JSON'));
    });
