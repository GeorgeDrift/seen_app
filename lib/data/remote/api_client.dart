import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';

/// Builds the Dio instance used to talk to the Azure Functions backend.
///
/// The function key is injected as a `?code=...` query parameter on every
/// request via an interceptor so per-call code never has to remember it —
/// same key handling as the `curl` examples in the backend README.
class ApiClient {
  ApiClient(this.config)
    : dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 10),
          headers: const {'Content-Type': 'application/json'},
        ),
      ) {
    if (config.isConfigured) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final params = Map<String, dynamic>.from(options.queryParameters);
            params.putIfAbsent('code', () => config.functionKey);
            options.queryParameters = params;
            handler.next(options);
          },
        ),
      );
    }
  }

  final ApiConfig config;
  final Dio dio;

  bool get isConfigured => config.isConfigured;
}
