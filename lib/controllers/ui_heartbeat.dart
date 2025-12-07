import "package:flutter/foundation.dart";

/// Lightweight controller for triggering UI rebuilds.
/// 
/// When answers change (typing/toggling), call UiHeartbeat.ping().
/// Widgets that watch UiHeartbeat will rebuild to reflect the changes.
/// 
/// This is a simple notification mechanism that avoids rebuilding
/// entire controller hierarchies when only answer display needs to update.
class UiHeartbeat extends ChangeNotifier {
  /// Notify all listeners to rebuild.
  void ping() => notifyListeners();
}
