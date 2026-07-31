import 'dart:developer' as developer;

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
          // Generous margin above the longest server-side AI timeout
          // (weeklyInsightsEngine's 12s) plus Azure Functions Consumption
          // plan cold-start overhead (the function host itself can take
          // several seconds to spin up after being idle, on top of the AI
          // call). A tighter client timeout than the server's own budget
          // meant the first request after any idle period would silently
          // time out client-side and fall back to the generic local
          // reflection, while a second attempt (now-warm instance) would
          // succeed — see the "first click returns nothing" reflection bug.
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
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

    // Every real network call (or the lack of one) shows up here, tagged
    // "Backend" — this is the ground truth for whether the AI/backend is
    // actually being hit, independent of what the repository decided to
    // fall back to.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          developer.log(
            '-> ${options.method} ${options.uri.path}',
            name: 'Backend',
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            '<- ${response.statusCode} ${response.requestOptions.uri.path}',
            name: 'Backend',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          developer.log(
            '<- ERROR ${error.requestOptions.uri.path}: '
            '${error.type} ${error.message ?? ''}',
            name: 'Backend',
          );
          handler.next(error);
        },
      ),
    );
  }

  final ApiConfig config;
  final Dio dio;

  bool get isConfigured => config.isConfigured;
}
