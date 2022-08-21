import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/channel.dart';
import 'package:isolation/src/connection.dart';
import 'package:isolation/src/exception.dart';
import 'package:isolation/src/logging.dart';
import 'package:meta/meta.dart';

/// {@template slave_connection}
/// Isolate helper, that helps to create and manage another isolate.
/// {@endtemplate}
@internal
class SlaveConnection<In, Out> extends Connection<In, Out> {
  /// {@macro slave_isolate_connection}
  SlaveConnection({
    required SendPort dataSendPort,
    required SendPort exceptiondataSendPort,
    required SendPort servicedataSendPort,
    required EventSink<Out> out,
    String? debugName = 'SlaveConnection',
  })  : _debugName = debugName,
        _eventsFromMaster = out,
        super(
          dataChannel: IsolateChannel<In, Out>(
            dataSendPort,
          ),
          exceptionChannel: IsolateChannel<IsolateException, IsolateException>(
            exceptiondataSendPort,
          ),
          serviceChannel: IsolateChannel<Object?, Object?>(
            servicedataSendPort,
          ),
        ) {
    fine('$_debugName created');
  }

  /// Combine data and exception from master isolate
  final EventSink<Out> _eventsFromMaster;

  StreamSubscription<Out>? _dataSubscription;
  StreamSubscription<IsolateException>? _exceptionSubscription;
  StreamSubscription<Object?>? _serviceSubscription;

  /// Debug name
  final String? _debugName;

  @override
  Future<void> connect() async {
    assert(status.isNotConnected, '$_debugName has already been established.');
    if (!status.isNotConnected) return;
    fine('$_debugName connection is started');
    await super.connect();
    addServiceMessage(
      <SendPort>[
        super.dataChannel.receivePort.sendPort,
        super.exceptionChannel.receivePort.sendPort,
        super.serviceChannel.receivePort.sendPort,
      ],
    );
    _registrateListeners();
  }

  void _registrateListeners() {
    fine('$_debugName start listening on data channel');
    _dataSubscription = dataChannel.receivePort.cast<Out>().listen(
      _eventsFromMaster.add,
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          '$_debugName exception on data channel listener',
        );
        _eventsFromMaster.addError(error, stackTrace);
      },
      cancelOnError: false,
    );

    fine('$_debugName start listening on exception channel');
    _exceptionSubscription =
        exceptionChannel.receivePort.cast<IsolateException>().listen(
      (msg) => _eventsFromMaster.addError(msg.exception, msg.stackTrace),
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          '$_debugName exception on exception channel listener',
        );
        _eventsFromMaster.addError(error, stackTrace);
      },
      cancelOnError: false,
    );

    fine('$_debugName start listening on service channel');
    _serviceSubscription = serviceChannel.receivePort.cast<Object?>().listen(
      (msg) {
        if (msg == null) {
          close();
          return;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          '$_debugName exception on exception service listener',
        );
        _eventsFromMaster.addError(error, stackTrace);
      },
      cancelOnError: false,
    );
  }

  @override
  Future<void> close({bool force = false}) async {
    try {
      config('$_debugName is closing');
      addServiceMessage(null);
      super.close();
      _dataSubscription?.cancel().ignore();
      _exceptionSubscription?.cancel().ignore();
      _serviceSubscription?.cancel().ignore();
      if (!force) {
        // ignore: todo
        // TODO: await all data and exception before kill
      }
    } finally {
      config('$_debugName is closed');
      Isolate.current.kill();
    }
  }
}
