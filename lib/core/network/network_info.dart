import 'package:flutter/foundation.dart';

/// Abstract interface for network connectivity checking
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementation of NetworkInfo for checking network connectivity
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      // In a real implementation, you might use connectivity_plus package
      // For now, we'll assume connection is available
      // This is a simplified implementation
      return true;
    } catch (_) {
      return false;
    }
  }
}
