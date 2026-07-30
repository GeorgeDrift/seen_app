import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/seen_api.dart';
import '../../data/repositories/seen_repository_impl.dart';
import '../../domain/repositories/seen_repository.dart';

/// The single wiring file for external dependencies. Every downstream
/// controller reads only the repository — never dio, never the API client
/// directly — so swapping either one is a one-line change here.

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(apiConfigProvider));
});

final seenApiProvider = Provider<SeenApi>((ref) {
  return SeenApi(ref.watch(apiClientProvider));
});

final seenRepositoryProvider = Provider<SeenRepository>((ref) {
  return SeenRepositoryImpl(api: ref.watch(seenApiProvider));
});
