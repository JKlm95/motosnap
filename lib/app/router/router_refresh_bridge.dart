import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a [Stream] to [Listenable] for `GoRouter.refreshListenable`.
///
/// `go_router` previously exported `GoRouterRefreshStream`; this thin adapter
/// avoids version coupling while keeping the same pattern as mature Flutter apps.
final class RouterRefreshBridge extends ChangeNotifier {
  RouterRefreshBridge(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
