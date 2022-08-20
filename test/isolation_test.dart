import 'package:isolation/isolation.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    late IsolateController controller;

    setUp(() {
      controller = IsolateController<int, String>(pow2);
    });

    tearDown(() {
      controller.close();
    });

    test('4 ^ 2', () {
      controller.add(4);
      return expectLater(
        controller.stream,
        emitsInOrder(<Object?>[
          '4 ^ 2 = 16',
          emitsDone,
        ]),
      );
    });
  });
}

Future<void> pow2(IsolateController<String, int> controller) async {
  final value = await controller.stream.first;
  controller.add('$value ^ 2 = ${value * value}');
  await controller.close();
}
