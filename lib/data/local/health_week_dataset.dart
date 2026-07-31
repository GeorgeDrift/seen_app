import '../models/demo_profile.dart';
import '../models/health_week_day.dart';

class HealthWeekDataset {
  static List<HealthWeekDay> forProfile(DemoProfileKey? key) {
    switch (key) {
      case DemoProfileKey.b:
        return _profileB;
      case DemoProfileKey.c:
        return _profileC;
      case DemoProfileKey.a:
      case null:
        return _profileA;
    }
  }

  // Profile A — Overloaded: poor sleep, low movement, packed calendar, rain.
  // Themes: "feeling behind before starting", "small progress brought relief".
  static final List<HealthWeekDay> _profileA = [
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

  // Profile B — Active: good sleep, high movement, sunny, light calendar.
  // Themes: "movement as a reset", "energy from being outdoors".
  static final List<HealthWeekDay> _profileB = [
    HealthWeekDay(
      date: '2026-06-02',
      sleep: const HealthWeekSleep(durationHours: 7.9),
      movement: const HealthWeekMovement(
        steps: 11200,
        relativeLevel: 'Higher than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 78),
      calendar: const HealthWeekCalendar(eventCount: 1, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 2, 19, 45),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Walking shoes',
            meaning: 'The long walk cleared my head completely.',
          ),
          HealthWeekClueMeaning(
            name: 'Open window',
            meaning: 'Fresh air made the afternoon feel lighter.',
          ),
        ],
        finalText:
            'Getting outside early set the tone for the whole day. '
            'I felt more present and less scattered than usual.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-03',
      sleep: const HealthWeekSleep(durationHours: 8.1),
      movement: const HealthWeekMovement(
        steps: 9400,
        relativeLevel: 'Higher than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 81),
      calendar: const HealthWeekCalendar(eventCount: 2, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 3, 20, 10),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Water bottle',
            meaning: 'Staying hydrated kept me focused during the run.',
          ),
        ],
        finalText:
            'Running in the morning gave me energy that lasted all day. '
            'I noticed I was calmer in conversations too.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-04',
      sleep: const HealthWeekSleep(durationHours: 7.4),
      movement: const HealthWeekMovement(steps: 6200, relativeLevel: 'Usual'),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 73),
      calendar: const HealthWeekCalendar(eventCount: 3, load: 'Moderate'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 4, 20, 30),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Headphones',
            meaning: 'Music helped me push through a slower afternoon.',
          ),
        ],
        finalText:
            'A cloudier day slowed me down a bit, but I still got outside. '
            'Even a short walk helped reset my focus.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-05',
      sleep: const HealthWeekSleep(durationHours: 7.7),
      movement: const HealthWeekMovement(
        steps: 12500,
        relativeLevel: 'Higher than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 80),
      calendar: const HealthWeekCalendar(eventCount: 0, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 5, 19, 20),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Walking shoes',
            meaning: 'Hiked a new trail and it felt like an adventure.',
          ),
        ],
        finalText:
            'No meetings, lots of sun, and a long hike. This is the kind '
            'of day I want more of.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-06',
      sleep: const HealthWeekSleep(durationHours: 6.8),
      movement: const HealthWeekMovement(steps: 5100, relativeLevel: 'Usual'),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 71),
      calendar: const HealthWeekCalendar(eventCount: 4, load: 'Moderate'),
      reflection: const HealthWeekReflection(completed: false),
    ),
    HealthWeekDay(
      date: '2026-06-07',
      sleep: const HealthWeekSleep(durationHours: 8.3),
      movement: const HealthWeekMovement(
        steps: 10800,
        relativeLevel: 'Higher than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 77),
      calendar: const HealthWeekCalendar(eventCount: 1, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 7, 19, 55),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Open window',
            meaning: 'The breeze reminded me to slow down and enjoy the evening.',
          ),
        ],
        finalText:
            'I felt energized all day after sleeping well and getting '
            'outside early. Movement really does change my mood.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-08',
      sleep: const HealthWeekSleep(durationHours: 7.5),
      movement: const HealthWeekMovement(
        steps: 8900,
        relativeLevel: 'Higher than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Sunny', temperatureF: 79),
      calendar: const HealthWeekCalendar(eventCount: 2, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 8, 20, 5),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Walking shoes',
            meaning: 'An evening walk with a friend felt restorative.',
          ),
        ],
        finalText:
            'Being outdoors with someone I care about was the highlight. '
            'I notice I feel best on days when I move and connect.',
      ),
    ),
  ];

  // Profile C — Quiet Recovery: restless sleep, low movement, empty calendar,
  // cloudy/rainy. Themes: "needing rest but not finding it", "comfort in
  // stillness".
  static final List<HealthWeekDay> _profileC = [
    HealthWeekDay(
      date: '2026-06-16',
      sleep: const HealthWeekSleep(durationHours: 5.2),
      movement: const HealthWeekMovement(
        steps: 1800,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Rainy', temperatureF: 59),
      calendar: const HealthWeekCalendar(eventCount: 0, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 16, 23, 10),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Blanket',
            meaning: 'I stayed wrapped up most of the day. Felt safe there.',
          ),
          HealthWeekClueMeaning(
            name: 'Candle',
            meaning: 'Lighting it was the only intentional thing I did.',
          ),
        ],
        finalText:
            'I woke up tired and never really shook it off. The rain '
            'outside matched how I felt inside — heavy and slow.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-17',
      sleep: const HealthWeekSleep(durationHours: 6.0),
      movement: const HealthWeekMovement(
        steps: 2400,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 62),
      calendar: const HealthWeekCalendar(eventCount: 1, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 17, 22, 45),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Book',
            meaning: 'Reading was the only thing that felt manageable.',
          ),
        ],
        finalText:
            'I didn\'t do much today, but reading for an hour felt like '
            'enough. Sometimes doing less is the right thing.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-18',
      sleep: const HealthWeekSleep(durationHours: 5.6),
      movement: const HealthWeekMovement(
        steps: 3100,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Rainy', temperatureF: 58),
      calendar: const HealthWeekCalendar(eventCount: 0, load: 'Light'),
      reflection: const HealthWeekReflection(completed: false),
    ),
    HealthWeekDay(
      date: '2026-06-19',
      sleep: const HealthWeekSleep(durationHours: 4.9),
      movement: const HealthWeekMovement(
        steps: 2000,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 61),
      calendar: const HealthWeekCalendar(eventCount: 0, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 19, 23, 30),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Blanket',
            meaning: 'Couldn\'t sleep again. The blanket was the only comfort.',
          ),
        ],
        finalText:
            'Another rough night. I feel stuck in a loop of being tired '
            'but unable to rest properly.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-20',
      sleep: const HealthWeekSleep(durationHours: 6.3),
      movement: const HealthWeekMovement(steps: 3500, relativeLevel: 'Usual'),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 64),
      calendar: const HealthWeekCalendar(eventCount: 1, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 20, 22, 20),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Tea',
            meaning: 'Making tea was a small ritual that grounded me.',
          ),
        ],
        finalText:
            'Slept a little better. A warm drink and a quiet morning '
            'helped me feel slightly more like myself.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-21',
      sleep: const HealthWeekSleep(durationHours: 5.4),
      movement: const HealthWeekMovement(
        steps: 1900,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Rainy', temperatureF: 57),
      calendar: const HealthWeekCalendar(eventCount: 0, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 21, 23, 5),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Candle',
            meaning: 'The flickering light was calming when everything else felt loud.',
          ),
        ],
        finalText:
            'I need rest but my body won\'t cooperate. Sitting quietly '
            'with a candle was the closest I got to peace today.',
      ),
    ),
    HealthWeekDay(
      date: '2026-06-22',
      sleep: const HealthWeekSleep(durationHours: 6.5),
      movement: const HealthWeekMovement(
        steps: 2800,
        relativeLevel: 'Lower than usual',
      ),
      weather: const HealthWeekWeather(condition: 'Cloudy', temperatureF: 63),
      calendar: const HealthWeekCalendar(eventCount: 0, load: 'Light'),
      reflection: HealthWeekReflection(
        completed: true,
        submittedAt: DateTime(2026, 6, 22, 22, 50),
        selectedClues: const [
          HealthWeekClueMeaning(
            name: 'Book',
            meaning: 'Lost myself in a story for a couple hours. It helped.',
          ),
        ],
        finalText:
            'A slightly better night. I\'m starting to notice that the '
            'small comforts — a book, a warm drink — do add up.',
      ),
    ),
  ];
}
