@Timeout(Duration(seconds: 5))

import 'package:isolation/isolation.dart';
import 'package:test/test.dart';

void main() => group(
      'echo',
      () {
        late IsolateController<String, String> controller;

        setUpAll(() {
          controller = IsolateController<String, String>(_echo);
        });

        tearDownAll(() {
          controller.close();
        });

        test('single', () {
          controller.add('ping');
          expect(
            controller.stream.first,
            completion(equals('ping')),
          );
        });

        test('double', () {
          controller
            ..add('1')
            ..add('2');
          expectLater(
            controller.stream.take(2),
            emitsInOrder(<String>['1', '2']),
          );
        });
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

Future<void> _echo(IsolateController<String, String> controller) =>
    controller.stream.forEach((event) => controller.add(event));
