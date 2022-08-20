import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:isolation/src/logging.dart';
import 'package:meta/meta.dart';

/// Async callback
typedef EventCallback = FutureOr<void> Function();

/// {@template event_queue}
/// An event queue is a queue of [EventCallback]s that are executed in order.
/// {@endtemplate}
class EventQueue implements Sink<EventCallback> {
  /// {@macro event_queue}
  EventQueue({String? debugLabel}) {
    _debugLabel = debugLabel ??
        (const bool.fromEnvironment('dart.vm.product')
            ? 'EventQueue'
            : 'EventQueue#$hashCode');
  }

  /// Is the queue closed?
  bool get isClosed => _closed;
  bool _closed = false;
  final Queue<_EventQueueTask> _queue = Queue<_EventQueueTask>();
  late final String? _debugLabel;
  Future<void>? _processing;

  @override
  Future<void> add(EventCallback event) {
    if (_closed) {
      throw StateError('EventQueue is closed');
    }
    final task = _EventQueueTask(event);
    _queue.add(task);
    developer.Timeline.instantSync('$_debugLabel:add');
    _start().ignore();
    return task.future;
  }

  @override
  Future<void> close({bool force = false}) async {
    _closed = true;
    if (force) {
      _queue.clear();
    } else {
      await _processing;
    }
  }

  Future<void> _start() {
    final processing = _processing;
    if (processing != null) {
      return processing;
    }
    final flow = developer.Flow.begin();
    developer.Timeline.instantSync('$_debugLabel:begin');
    return _processing = Future.doWhile(() async {
      if (_queue.isEmpty) {
        _processing = null;
        developer.Timeline.instantSync('$_debugLabel:end');
        developer.Flow.end(flow.id);
        return false;
      }
      try {
        await developer.Timeline.timeSync(
          '$_debugLabel:task',
          _queue.removeFirst(),
          flow: developer.Flow.step(flow.id),
        );
      } on Object catch (error, stackTrace) {
        warning(error, stackTrace, '$_debugLabel:exception');
      }
      return true;
    });
  }
}

@immutable
class _EventQueueTask {
  _EventQueueTask(EventCallback event)
      : _fn = event,
        _completer = Completer<void>();

  final EventCallback _fn;
  final Completer<void> _completer;

  Future<void> get future => _completer.future;

  Future<void> call() async {
    try {
      await _fn();
      _completer.complete();
    } on Object catch (error, stackTrace) {
      _completer.completeError(error, stackTrace);
    }
  }
}
