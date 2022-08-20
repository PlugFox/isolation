import 'dart:isolate';

import 'package:meta/meta.dart';

/// {@template isolate_channel}
/// Channel between two isolates.
/// Used to send data, exception or service messages between isolates.
/// {@endtemplate}
@internal
class IsolateChannel<In extends Object?, Out extends Object?> extends Sink<In> {
  /// {@macro isolate_channel}
  IsolateChannel([SendPort? sendPort])
      : receivePort = ReceivePort(),
        _sendPort = sendPort;

  /// Isolate channel receive port already closed;
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  /// Contain [SendPort]
  bool get hasSendPort => _sendPort != null;

  /// Allow receiving data from the isolate.
  final ReceivePort receivePort;

  /// Allow sending data to another isolate.
  SendPort? _sendPort;

  /// Set new send port
  // ignore: use_setters_to_change_properties
  void setPort(SendPort sendPort) => _sendPort = sendPort;

  @override
  void add(In data) {
    assert(
      hasSendPort,
      'IsolateChannel is not connected to another isolate.',
    );
    _sendPort?.send(data);
  }

  @override
  void close() {
    if (isClosed) return;
    receivePort.close();
    _isClosed = true;
  }
}
