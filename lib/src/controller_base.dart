import 'dart:async';

import 'package:isolation/src/connection.dart';
import 'package:isolation/src/controller.dart';
import 'package:isolation/src/event_queue.dart';
import 'package:isolation/src/logging.dart';
import 'package:meta/meta.dart';

/// {@nodoc}
@internal
abstract class IsolateControllerBase<Input, Output>
    implements IsolateController<Input, Output> {
  /// {@nodoc}
  IsolateControllerBase({
    this.debugLabel,
  }) : eventQueue = EventQueue(
          debugLabel: debugLabel == null ? null : 'EventQueue#$debugLabel',
        );

  /// {@nodoc}
  @protected
  abstract final Connection connection;

  /// {@nodoc}
  @protected
  @nonVirtual
  final EventQueue eventQueue;

  /// {@nodoc}
  @protected
  @nonVirtual
  final String? debugLabel;

  /// {@nodoc}
  @protected
  @nonVirtual
  late final StreamController<Output> outputController =
      StreamController<Output>.broadcast();

  @override
  @nonVirtual
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  @override
  @useResult
  @nonVirtual
  Stream<Output> get stream => outputController.stream;

  @override
  @nonVirtual
  void add(Input event) {
    if (_isClosed) return;
    if (connection.status.isNotConnected) {
      eventQueue.add(() {
        assert(!_isClosed, 'Cannot be added to a closed controller');
        if (_isClosed) return Future<void>.value();
        return connection.connect();
      });
    }
    eventQueue.add(() {
      assert(!_isClosed, 'Cannot be added to a closed controller');
      if (_isClosed) return;
      connection.add(event);
    });
  }

  @override
  @nonVirtual
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_isClosed) return;
    eventQueue.add(() {
      assert(!_isClosed, 'Cannot be added to a closed controller');
      connection.addError(error, stackTrace);
    });
  }

  @override
  @mustCallSuper
  Future<void> close({bool force = false}) async {
    if (_isClosed) return;
    if (force) {
      config('$debugLabel closing');
      await eventQueue.close(force: true);
      await connection.close(force: true);
      await outputController.close();
      _isClosed = true;
    } else {
      eventQueue
        // ignore: unawaited_futures
        ..add(() => config('$debugLabel closing'))
        // ignore: unawaited_futures
        ..add(connection.close)
        // ignore: unawaited_futures
        ..add(outputController.close)
        // ignore: unawaited_futures
        ..add(() => _isClosed = true)
        // ignore: unawaited_futures
        ..add(eventQueue.close);
    }
  }
}
