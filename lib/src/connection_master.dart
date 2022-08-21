import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/channel.dart';
import 'package:isolation/src/connection.dart';
import 'package:isolation/src/constant.dart';
import 'package:isolation/src/entry_point.dart';
import 'package:isolation/src/exception.dart';
import 'package:isolation/src/handler.dart';
import 'package:isolation/src/logging.dart';
import 'package:isolation/src/payload.dart';
import 'package:meta/meta.dart';

/// {@template master_connection}
/// Isolate helper, that helps to create and manage another isolate.
/// {@endtemplate}
@internal
class MasterConnection<In, Out> extends Connection<In, Out> {
  /// {@macro master_connection}
  MasterConnection({
    required IsolateHandler<In, Out> handler,
    required EventSink<Out> out,
    String? debugName = 'MasterConnection',
  })  : _handler = handler,
        _eventsFromSlave = out,
        _debugName = debugName,
        super(
          dataChannel: IsolateChannel<In, Out>(),
          exceptionChannel:
              IsolateChannel<IsolateException, IsolateException>(),
          serviceChannel: IsolateChannel<Object?, Object?>(),
        ) {
    fine('$_debugName created');
  }

  /// Slave isolation
  Isolate? _slaveIsolate;

  /// Handler for slave's events
  final EventSink<Out> _eventsFromSlave;

  /// Entry point
  final IsolateHandler<In, Out> _handler;

  /// Debug name
  final String? _debugName;

  /// Subscription for data from slave
  StreamSubscription<Out>? _dataSubscription;

  /// Subscription for errors from slave
  StreamSubscription<IsolateException>? _exceptionSubscription;

  /// Subscription for service messages from slave
  StreamSubscription<Object?>? _serviceSubscription;

  @override
  Future<void> connect() async {
    assert(status.isNotConnected, '$_debugName has already been established.');
    if (!status.isNotConnected) return;
    await super.connect();
    fine('$_debugName starts connection');
    // Payload for slave isolate.
    final payload = IsolatePayload<In, Out>(
      dataPort: super.dataChannel.receivePort.sendPort,
      exceptionPort: super.exceptionChannel.receivePort.sendPort,
      servicePort: super.serviceChannel.receivePort.sendPort,
      handler: _handler,
      errorsAreFatal: false,
      enableLogging: Zone.current[kLogEnabled] == true,
    );
    final registrateListenersFuture = _registrateListeners();
    _slaveIsolate = await Isolate.spawn<IsolatePayload<In, Out>>(
      isolateEntryPoint,
      payload,
      errorsAreFatal: payload.errorsAreFatal,
      onExit: payload.servicePort,
      debugName: _debugName,
    ).timeout(const Duration(milliseconds: 30000));
    await registrateListenersFuture
        .timeout(const Duration(milliseconds: 30000));
  }

  Future<void> _registrateListeners() {
    fine('$_debugName start listening on data channel');
    _dataSubscription = dataChannel.receivePort.cast<Out>().listen(
      _eventsFromSlave.add,
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          '$_debugName exception on data channel listener',
        );
        _eventsFromSlave.addError(error, stackTrace);
      },
      cancelOnError: false,
    );

    fine('$_debugName start listening on exception channel');
    _exceptionSubscription =
        exceptionChannel.receivePort.cast<IsolateException>().listen(
      (msg) => _eventsFromSlave.addError(msg.exception, msg.stackTrace),
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          '$_debugName exception on exception channel listener',
        );
        _eventsFromSlave.addError(error, stackTrace);
      },
      cancelOnError: false,
    );

    fine('$_debugName start listening on service channel');
    final completer = Completer<void>();
    _serviceSubscription = serviceChannel.receivePort.cast<Object?>().listen(
      (msg) {
        if (!completer.isCompleted) {
          if (msg is! List<SendPort> || msg.length != 3) {
            warning(
              'Instead SendPorts received unexpected message',
            );
            throw UnsupportedError('Unexpected message');
          }
          fine('$_debugName recive send ports from SlaveConnection');
          super.dataChannel.setPort(msg[0]);
          super.exceptionChannel.setPort(msg[1]);
          super.serviceChannel.setPort(msg[2]);
          completer.complete();
        }
      },
    );
    return completer.future;
  }

  @override
  Future<void> close({bool force = false}) async {
    try {
      config('$_debugName is closing');
      addServiceMessage(null);
      if (!force) {
        // ignore: todo
        // TODO: await response from slave isolate.
        //_slaveIsolate.addOnExitListener(responsePort)
      }
      super.close(force: force);
      await _dataSubscription?.cancel();
      await _exceptionSubscription?.cancel();
      await _serviceSubscription?.cancel();
    } finally {
      _slaveIsolate?.kill();
      config('$_debugName is closed');
    }
  }
}
