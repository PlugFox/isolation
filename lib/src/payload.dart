import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/connection.dart';
import 'package:isolation/src/controller_slave.dart';
import 'package:isolation/src/handler.dart';
import 'package:meta/meta.dart';

/// {@template isolate_payload}
/// IsolatePayload class
/// {@endtemplate}
@internal
@immutable
class IsolatePayload<In, Out> {
  /// {@macro isolate_payload}
  const IsolatePayload({
    required this.dataPort,
    required this.exceptionPort,
    required this.servicePort,
    required this.handler,
    required this.enableLogging,
    required this.errorsAreFatal,
  });

  /// Isolate payload data port
  final SendPort dataPort;

  /// Isolate payload exception port
  final SendPort exceptionPort;

  /// Isolate payload service port
  final SendPort servicePort;

  /// Handler
  final IsolateHandler<In, Out> handler;

  /// Enable logging
  final bool enableLogging;

  /// Sets whether uncaught errors will terminate the isolate.
  final bool errorsAreFatal;

  /// Finish slave isolate initialization
  Future<Connection<Out, In>> call() async {
    try {
      // ignore: close_sinks
      final controller = IsolateControllerSlaveImpl<Out, In>(
        dataSendPort: dataPort,
        exceptiondataSendPort: exceptionPort,
        servicedataSendPort: servicePort,
      );
      await controller.connection.connect();
      // Workaround with handler to save types between isolates:
      Future<void>(() => handler(controller)).ignore();
      return controller.connection;
    } on Object {
      rethrow;
    }
  }
}
