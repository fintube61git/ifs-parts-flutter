import "package:flutter/foundation.dart";

/// When answers change (typing/toggling), call UiHeartbeat.ping().
/// Widgets that watch UiHeartbeat will rebuild.
class UiHeartbeat extends ChangeNotifier {
  void ping() => notifyListeners();
}
