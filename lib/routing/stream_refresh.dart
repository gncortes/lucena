import 'dart:async';

import 'package:flutter/foundation.dart';

/// Avisa o roteador (`refreshListenable`) a cada valor de [stream], para ele
/// refazer os redirects.
class StreamRefresh extends ChangeNotifier {
  StreamRefresh(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
