import '../di/service_locator.dart';
import '../network/http_client.dart';
import '../network/network_info.dart';
import '../../features/auth/di/auth_injection.dart';
import '../../features/learn/di/learn_injection.dart';
import '../../features/community/di/community_injection.dart';
import '../../features/check/di/check_injection.dart';

/// Initialize all core dependencies
Future<void> initializeDependencies() async {
  // Core services
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl());
  sl.registerSingleton<HttpClient>(DioHttpClient());
}

/// Initialize feature-specific dependencies
/// This will be called by each feature module
Future<void> initializeFeatureDependencies() async {
  // Initialize authentication feature
  await initAuthDependencies();

  // Initialize learn feature
  await initLearnDependencies();

  // Initialize community feature
  await initCommunityDependencies();

  // Initialize check feature
  await initCheckDependencies();

  // Other features will be added here as they are restructured
}
