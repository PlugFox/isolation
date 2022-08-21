@Timeout(Duration(seconds: 5))

import 'package:isolation/isolation.dart';
import 'package:test/test.dart';

void main() => group(
      'pow',
      () {
        late IsolateController<int, String> controller;

        setUpAll(() {
          controller = IsolateController<int, String>(_pow2);
        });

        tearDownAll(() {
          controller.close();
        });

        test('single', () {
          expect((controller..add(4)).stream.first, completion(equals('16')));
        });

        test('double', () {
          controller
            ..add(1)
            ..add(2);
          expectLater(
            controller.stream.take(2),
            emitsInOrder(<String>['1', '4']),
          );
        });
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

Future<void> _pow2(IsolateController<String, int> controller) =>
    controller.stream.forEach((e) => controller.add('${e * e}'));
