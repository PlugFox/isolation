@Timeout(Duration(seconds: 5))

import 'dart:async';

import 'package:isolation/isolation.dart';
import 'package:test/test.dart';

void main() => group(
      'pow',
      () {
        test('single', () async {
          final controller = IsolateController<int, String>(_pow2);
          await expectLater(
            (controller..add(4)).stream.first,
            completion(equals('16')),
          );
          await controller.close();
        });

        test('double', () async {
          final controller = IsolateController<int, String>(_pow2)
            ..add(1)
            ..add(2);
          await expectLater(
            controller.stream.take(2),
            emitsInOrder(<String>['1', '4']),
          );
          await controller.close();
        });
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

Future<void> _pow2(IsolateController<String, int> controller) =>
    controller.stream.forEach((e) => controller.add('${e * e}'));
