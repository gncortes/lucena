import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FrameTiming, PlatformDispatcher;

import 'package:flutter/widgets.dart';

/// Profile-target instrumentation. Records only engine timings and fixture
/// segment names, never positions, preferences, accounts or network data.
class NativeFrameRecorder {
  final _file = File(
    '${Directory.systemTemp.path}/t85-native-frame-times.jsonl',
  );
  final _pending = <Map<String, Object>>[];
  Future<void> _writes = Future.value();
  String _segment = 'startup';

  void start() {
    final hz = PlatformDispatcher.instance.views.first.display.refreshRate;
    _pending.add({'event': 'process_start', 'refreshHz': hz});
    WidgetsBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
      for (final frame in timings) {
        _pending.add({
          'segment': _segment,
          'buildUs': frame.buildDuration.inMicroseconds,
          'rasterUs': frame.rasterDuration.inMicroseconds,
          'totalUs': frame.totalSpan.inMicroseconds,
        });
      }
    });
    Timer.periodic(const Duration(seconds: 1), (_) => _flush());
  }

  void segment(String name) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,40}$').hasMatch(name)) return;
    _segment = name;
    _pending.add({'event': 'segment', 'segment': name});
  }

  void _flush() {
    if (_pending.isEmpty) return;
    final text = '${_pending.map(jsonEncode).join('\n')}\n';
    _pending.clear();
    _writes = _writes.then((_) async {
      await _file.writeAsString(text, mode: FileMode.append, flush: true);
    });
  }
}
