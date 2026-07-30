import '../models/health_week_day.dart';

/// Fixed 7-day dummy dataset for the "Health over time" prototype — no live
/// device/backend integration required for this pass. Same shape used to
/// verify the live `/week/insights` endpoint during development: 6 of 7 days
/// completed (one missed, 2026-05-14), two recurring themes each appearing
/// across 2+ days ("feeling behind before starting" / "small progress
/// brought relief"), varied sleep/movement/weather/calendar so the passive-
/// context timeline has real variation to render, and evening submission
/// times that vary slightly so the reflection-habits calculation has
/// something real to summarize.
class HealthWeekDataset {
  static final List<HealthWeekDay> demo = [
    HealthWeekDay(
      date: '2026-05-12',
      sleep: const HealthWeekSleep(durationHours: 5.8),
      movement: const HealthWeekMovement(
        steps: 3210,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Rainy', temperatureF: 64),
      calendar: const HealthWeekCalendar(eventCount: 5, load: 'Busy'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 5, 12, 22, 14),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Laptop',
            meaning: 'I kept thinking about everything I needed to finish.',
          ),
          HealthWeekClueMeaning(
            name: 'Unfinished coffee',
            meaning: 'I was distracted and forgot about it.',
          ),
        ],
        finalText:
            'I felt behind before I even opened my laptop. Everything '
            'seemed like too much, so I kept avoiding the task.',
      ),
    ),
    HealthWeekDay(
      date: '2026-05-13',
      sleep: const HealthWeekSleep(durationHours: 7.2),
      movement: const HealthWeekMovement(
        steps: 7348,
        relativeLevel: 'Higher than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 72),
      calendar: const HealthWeekCalendar(eventCount: 2, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 5, 13, 21, 8),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Walking shoes',
            meaning: 'Going outside gave me a break from thinking about work.',
          ),
        ],
        finalText:
            'I still felt overwhelmed, but going outside helped me feel '
            'clearer. Once I completed one small task, I felt less stuck.',
      ),
    ),
    HealthWeekDay(
      date: '2026-05-14',
      sleep: const HealthWeekSleep(durationHours: 6.1),
      movement: const HealthWeekMovement(steps: 4100, relativeLevel: 'Usual'),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 68),
      calendar: const HealthWeekCalendar(eventCount: 4, load: 'Moderate'),
      reflection: const HealthWeekReflection(completed: false),
    ),
    HealthWeekDay(
      date: '2026-05-15',
      sleep: const HealthWeekSleep(durationHours: 5.5),
      movement: const HealthWeekMovement(
        steps: 2900,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Rainy', temperatureF: 61),
      calendar: const HealthWeekCalendar(eventCount: 6, load: 'Busy'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 5, 15, 22, 40),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Laptop',
            meaning: 'So many meetings back to back, I felt behind all day.',
          ),
        ],
        finalText:
            'I felt behind before I even sat down to work. It was hard to '
            'start with so much already on my calendar.',
      ),
    ),
    HealthWeekDay(
      date: '2026-05-16',
      sleep: const HealthWeekSleep(durationHours: 7.6),
      movement: const HealthWeekMovement(
        steps: 8100,
        relativeLevel: 'Higher than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 75),
      calendar: const HealthWeekCalendar(eventCount: 1, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 5, 16, 20, 55),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Checklist',
            meaning: 'Crossing off one thing made the rest feel possible.',
          ),
        ],
        finalText:
            'Finishing one thing made the rest feel more possible. I felt '
            'calmer once I got moving.',
      ),
    ),
    HealthWeekDay(
      date: '2026-05-17',
      sleep: const HealthWeekSleep(durationHours: 5.9),
      movement: const HealthWeekMovement(
        steps: 3400,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 66),
      calendar: const HealthWeekCalendar(eventCount: 5, load: 'Busy'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 5, 17, 21, 50),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Unfinished coffee',
            meaning: 'Too much on my plate today, kept getting distracted.',
          ),
        ],
        finalText:
            'Everything seemed like too much, so I kept avoiding the task '
            'until late afternoon.',
      ),
    ),
    HealthWeekDay(
      date: '2026-05-18',
      sleep: const HealthWeekSleep(durationHours: 7.4),
      movement: const HealthWeekMovement(steps: 6800, relativeLevel: 'Usual'),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 70),
      calendar: const HealthWeekCalendar(eventCount: 2, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 5, 18, 21, 15),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Walking shoes',
            meaning: 'A short walk helped clear my head before starting.',
          ),
        ],
        finalText:
            'Once I completed one small task, I felt less stuck. Starting '
            'small made the whole day feel lighter.',
      ),
    ),
  ];
}
