import 'dart:async';

import 'package:meta/meta.dart';

/// Simple delegating wrapper around an [EventSink].
///
/// Subclasses can override individual methods, or use this to expose only the
/// [EventSink] methods of a subclass.
@internal
class DelegatingEventSink<T> implements EventSink<T> {
  final EventSink _sink;

  /// Create a delegating sink forwarding calls to [sink].
  DelegatingEventSink(EventSink<T> sink) : _sink = sink;

  @override
  void add(T data) => _sink.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);

  @override
  void close() => _sink.close();
}
