import 'package:dio/dio.dart';

import '../../core/errors/failures.dart';
import '../models/clue.dart';
import '../models/clue_selection.dart';
import '../models/daily_context.dart';
import '../models/daily_entry.dart';
import '../models/follow_up_question.dart';
import '../models/interpreted_signal.dart';
import '../models/pattern_observation.dart';
import 'api_client.dart';

/// Typed wrapper around the backend HTTP surface.
///
/// Every method throws a subclass of [Failure] (never a raw DioException) so
/// callers can pattern-match on the specific error shape they care about.
/// Only the AI endpoints are exercised in the current app — the rest of the
/// backend surface is exposed here so wiring more of it up later is a
/// one-line change in the repository, not a new file.
class SeenApi {
  const SeenApi(this._client);

  final ApiClient _client;

  bool get isConfigured => _client.isConfigured;

  Future<FollowUpQuestion> followUpQuestion({
    required Clue clue,
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    String? previousMeaning,
  }) async {
    final data = <String, dynamic>{
      'clue': clue.toJson(),
      'context': context.toJson(),
      'interpretedSignals':
          interpretedSignals.map((s) => s.toJson()).toList(),
      'previousMeaning': ?previousMeaning,
    };
    final res = await _guard(() =>
        _client.dio.post<Map<String, dynamic>>('/follow-up-question', data: data));
    return FollowUpQuestion.fromJson(res);
  }

  Future<DailyEntry> completeDay({
    required String date,
    required DailyContext context,
    required List<InterpretedSignal> interpretedSignals,
    required List<String> displayedClueIds,
    required List<ClueSelection> selectedClues,
  }) async {
    final data = <String, dynamic>{
      'date': date,
      'context': context.toJson(),
      'interpretedSignals':
          interpretedSignals.map((s) => s.toJson()).toList(),
      'displayedClueIds': displayedClueIds,
      'selectedClues': selectedClues.map((s) => s.toJson()).toList(),
    };
    final res = await _guard(() =>
        _client.dio.post<Map<String, dynamic>>('/day/complete', data: data));

    // The backend returns the saved DailyEntry, but with only the *backend*
    // Clue view (no icon/x/y/etc). We re-hydrate what the frontend needs
    // from the local catalog by clue id in the repository layer, so here
    // we only rebuild the ClueSelections and reuse the frontend's local
    // context for local rendering.
    return DailyEntry(
      id: res['id'] as String,
      date: res['date'] as String,
      context: DailyContext.fromJson(
          Map<String, dynamic>.from(res['context'] as Map)),
      interpretedSignals: (res['interpretedSignals'] as List)
          .cast<Map>()
          .map((m) => InterpretedSignal.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      displayedClueIds:
          (res['displayedClueIds'] as List).map((e) => e.toString()).toList(),
      selectedClues: selectedClues, // frontend-local (has clueTitle etc.)
      generatedSummary: res['generatedSummary'] as String? ?? '',
    );
  }

  Future<PatternObservation> patterns({
    required String clueA,
    required String clueB,
  }) async {
    final res = await _guard(() => _client.dio.get<Map<String, dynamic>>(
          '/patterns',
          queryParameters: {'clueA': clueA, 'clueB': clueB},
        ));
    return PatternObservation.fromJson(
        Map<String, dynamic>.from(res['observation'] as Map));
  }

  Future<Map<String, dynamic>> health() =>
      _guard(() => _client.dio.get<Map<String, dynamic>>('/health'));

  Future<T> _guard<T extends Object>(
      Future<Response<T>> Function() request) async {
    try {
      final res = await request();
      final body = res.data;
      if (body == null) {
        throw const ParseFailure('Empty response body from backend.');
      }
      return body;
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw ParseFailure('Malformed backend response: ${e.message}');
    }
  }

  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure('Backend did not respond in time.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return UnauthorizedFailure(
              'Backend rejected request (${code ?? '??'}). Function key wrong or missing?');
        }
        return ServerFailure(
          e.response?.statusMessage ?? 'Backend returned an error.',
          statusCode: code,
        );
      case DioExceptionType.connectionError:
        return NetworkFailure('Could not reach backend: ${e.message ?? ''}');
      case DioExceptionType.cancel:
        return const UnknownFailure('Request cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return UnknownFailure(e.message ?? 'Unknown backend error.');
      default:
        return UnknownFailure(e.message ?? 'Unknown backend error.');
    }
  }
}
