import 'dart:async';

import 'package:isolation/isolation.dart';

void main() => Future<void>(() async {
      final controller = IsolateController<int, String>(_callback, lazy: true)
        ..add(2)
        ..add(4)
        ..add(8);
      await controller.stream.take(3).forEach((msg) => print('f> $msg'));
      await controller.close(force: false);
    });

Future<void> _callback(IsolateController<String, int> controller) =>
    controller.stream.forEach((msg) {
      print('s> $msg');
      controller.add('$msg ^ 2 = ${msg * msg}');
    });
