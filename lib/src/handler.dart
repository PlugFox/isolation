import 'dart:async';

import 'package:isolation/src/controller.dart';

/// An event handler is responsible for reacting to an incoming [Input]
/// and can emit zero or more [Output] via the [controller]'s sink.
///
/// ```dart
/// void handler(IsolateController<String, Int> slaveController) =>
///   slaveController.stream.listen((i) =>
///     slaveController.sink.add('$i + $i = ${i * 2}')
///  );
///
/// final masterController = IsolateController<Int, String>(handler);
/// masterController.stream.listen(print); // prints: "2 + 2 = 4"
/// masterController.add(2);
/// masterController.close();
/// ```
typedef IsolateHandler<Input, Output> = FutureOr<void> Function(
  IsolateController<Output, Input> controller,
);
