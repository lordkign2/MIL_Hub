/// Simple service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    _services[T] = instance;
  }

  /// Register a factory function for lazy instantiation
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Get a registered service
  T get<T>() {
    // Check if we have a singleton instance
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    // Check if we have a factory
    if (_factories.containsKey(T)) {
      final instance = _factories[T]!() as T;
      // Store as singleton after first creation
      _services[T] = instance;
      return instance;
    }

    throw Exception(
      'Service of type $T not found. Make sure to register it first.',
    );
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Remove a service registration
  void unregister<T>() {
    _services.remove(T);
    _factories.remove(T);
  }

  /// Clear all registrations
  void reset() {
    _services.clear();
    _factories.clear();
  }
}

/// Global service locator instance for easy access
final sl = ServiceLocator();
