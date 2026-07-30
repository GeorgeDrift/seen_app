import 'dart:developer' as developer;

import 'package:device_calendar/device_calendar.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';

import '../models/daily_context.dart';

const String _logTag = 'PassiveData';

void _log(String message) => developer.log(message, name: _logTag);

/// One field of passive data plus where it actually came from — lets the
/// caller log a precise field-by-field report of what was real vs. demo.
class PassiveField<T> {
  const PassiveField.device(this.value) : source = 'device';
  const PassiveField.fallback(this.value) : source = 'fallback';

  final T value;
  final String source; // 'device' | 'fallback'
}

/// Everything this service could determine about today, each field tagged
/// with whether it came from the real device or had to fall back.
class PassiveDataResult {
  const PassiveDataResult({
    required this.sleepHours,
    required this.steps,
    required this.calendarEventCount,
    required this.calendarLoad,
    required this.weather,
  });

  final PassiveField<double?> sleepHours;
  final PassiveField<int?> steps;
  final PassiveField<int> calendarEventCount;
  final PassiveField<String> calendarLoad;
  final PassiveField<String> weather;
}

/// Collects real passive data from the phone — sleep + steps (HealthKit /
/// Health Connect via the `health` package), calendar load (device_calendar),
/// and weather (device location + Open-Meteo, no API key needed).
///
/// Every method here is safe to call with no permissions granted, no
/// network, or on a simulator with no real data: each returns null/fallback
/// rather than throwing, and every attempt (success, denial, or error) is
/// logged under the "PassiveData" tag via `dart:developer.log` so it's
/// visible in `flutter logs` / DevTools without needing a debugger attached.
class PassiveDataService {
  PassiveDataService({Health? health, DeviceCalendarPlugin? calendarPlugin, Dio? dio})
    : _health = health ?? Health(),
      _calendar = calendarPlugin ?? DeviceCalendarPlugin(),
      _dio = dio ?? Dio();

  final Health _health;
  final DeviceCalendarPlugin _calendar;
  final Dio _dio;

  /// Collects everything, falling back to [fallback]'s values field-by-field
  /// for anything that couldn't be read from the device.
  Future<PassiveDataResult> collect({required DailyContext fallback}) async {
    _log('Starting passive data collection…');

    final sleepAndSteps = await _collectHealth();
    final calendar = await _collectCalendar(fallback: fallback);
    final weather = await _collectWeather(fallback: fallback.weather);

    final sleepHours = sleepAndSteps.$1 ?? fallback.sleepHours;
    final steps = sleepAndSteps.$2 ?? fallback.steps;

    _log(
      'Collection complete — '
      'sleepHours=$sleepHours (${sleepAndSteps.$1 != null ? "device" : "fallback"}), '
      'steps=$steps (${sleepAndSteps.$2 != null ? "device" : "fallback"}), '
      'calendarEventCount=${calendar.$1} (${calendar.$3}), '
      'weather=${weather.$1} (${weather.$2})',
    );

    return PassiveDataResult(
      sleepHours: sleepAndSteps.$1 != null
          ? PassiveField.device(sleepHours)
          : PassiveField.fallback(sleepHours),
      steps: sleepAndSteps.$2 != null
          ? PassiveField.device(steps)
          : PassiveField.fallback(steps),
      calendarEventCount: calendar.$3 == 'device'
          ? PassiveField.device(calendar.$1)
          : PassiveField.fallback(calendar.$1),
      calendarLoad: calendar.$3 == 'device'
          ? PassiveField.device(calendar.$2)
          : PassiveField.fallback(calendar.$2),
      weather: weather.$2 == 'device'
          ? PassiveField.device(weather.$1)
          : PassiveField.fallback(weather.$1),
    );
  }

  // ── Health: sleep + steps ────────────────────────────────────────

  static const _sleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ];

  Future<(double?, int?)> _collectHealth() async {
    double? sleepHours;
    int? steps;

    try {
      await _health.configure();
      _log('Health.configure() completed.');

      final types = [..._sleepTypes, HealthDataType.STEPS];
      final granted = await _health.requestAuthorization(types);
      _log('Health.requestAuthorization($types) -> $granted');

      if (!granted) {
        _log('Health authorization denied — falling back for sleep+steps.');
        return (null, null);
      }

      sleepHours = await _readSleepHours();
      steps = await _readSteps();
    } catch (e, st) {
      _log('Health collection threw: $e\n$st');
    }

    return (sleepHours, steps);
  }

  Future<double?> _readSleepHours() async {
    try {
      final now = DateTime.now();
      // Look back far enough to catch a full overnight sleep session even
      // if "today" only just started.
      final since = now.subtract(const Duration(hours: 20));

      final points = await _health.getHealthDataFromTypes(
        startTime: since,
        endTime: now,
        types: _sleepTypes,
      );
      _log('Sleep query returned ${points.length} data point(s).');

      if (points.isEmpty) return null;

      final totalMinutes = points.fold<int>(
        0,
        (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes,
      );
      final hours = totalMinutes / 60.0;
      _log('Computed sleepHours=$hours from ${points.length} point(s).');
      return hours > 0 ? hours : null;
    } catch (e) {
      _log('Sleep read failed: $e');
      return null;
    }
  }

  Future<int?> _readSteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      _log('getTotalStepsInInterval -> $steps');
      return steps;
    } catch (e) {
      _log('Steps read failed: $e');
      return null;
    }
  }

  // ── Calendar ─────────────────────────────────────────────────────

  Future<(int, String, String)> _collectCalendar({
    required DailyContext fallback,
  }) async {
    try {
      var permission = await _calendar.hasPermissions();
      _log('Calendar hasPermissions -> ${permission.data}');

      if (permission.data != true) {
        permission = await _calendar.requestPermissions();
        _log('Calendar requestPermissions -> ${permission.data}');
      }

      if (permission.data != true) {
        _log('Calendar permission denied — falling back.');
        return (fallback.calendarEventCount, fallback.calendarLoad, 'fallback');
      }

      final calendarsResult = await _calendar.retrieveCalendars();
      final calendars = calendarsResult.data ?? [];
      _log('Found ${calendars.length} device calendar(s).');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      var eventCount = 0;
      for (final cal in calendars) {
        if (cal.id == null) continue;
        final eventsResult = await _calendar.retrieveEvents(
          cal.id,
          RetrieveEventsParams(startDate: startOfDay, endDate: endOfDay),
        );
        eventCount += (eventsResult.data ?? []).length;
      }

      final load = eventCount >= 6
          ? 'high'
          : (eventCount <= 1 ? 'low' : 'moderate');
      _log('Calendar eventCount=$eventCount -> load=$load');
      return (eventCount, load, 'device');
    } catch (e) {
      _log('Calendar collection failed: $e');
      return (fallback.calendarEventCount, fallback.calendarLoad, 'fallback');
    }
  }

  // ── Weather ──────────────────────────────────────────────────────

  Future<(String, String)> _collectWeather({required String fallback}) async {
    try {
      var permission = await Geolocator.checkPermission();
      _log('Location permission check -> $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        _log('Location permission request -> $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _log('Location permission denied — falling back for weather.');
        return (fallback, 'fallback');
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _log('Location services disabled — falling back for weather.');
        return (fallback, 'fallback');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      _log(
        'Got position lat=${position.latitude} lon=${position.longitude}',
      );

      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'current': 'temperature_2m,weather_code',
          'temperature_unit': 'fahrenheit',
        },
      );

      final current = response.data?['current'] as Map<String, dynamic>?;
      final code = (current?['weather_code'] as num?)?.toInt();
      final tempF = (current?['temperature_2m'] as num?)?.toDouble();
      _log('Open-Meteo current -> code=$code tempF=$tempF');

      if (code == null) {
        return (fallback, 'fallback');
      }

      final weather = _mapWeatherCode(code, tempF);
      return (weather, 'device');
    } catch (e) {
      _log('Weather collection failed: $e');
      return (fallback, 'fallback');
    }
  }

  /// Maps a WMO weather code (+ optional temperature) to this app's
  /// existing weather vocabulary: sunny | cloudy | rain | snow | hot | cold.
  String _mapWeatherCode(int code, double? tempF) {
    if (tempF != null) {
      if (tempF >= 85) return 'hot';
      if (tempF <= 34) return 'cold';
    }

    if (code == 0) return 'sunny';
    if (code <= 3 || code == 45 || code == 48) return 'cloudy';
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return 'snow';
    if ((code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        (code >= 95 && code <= 99)) {
      return 'rain';
    }
    return 'cloudy';
  }
}
