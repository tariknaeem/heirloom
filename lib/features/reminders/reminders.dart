import '../../models.dart';

/// A computed upcoming reminder (birthday or anniversary) for a given year.
class Reminder {
  /// Stable id so the same occurrence keeps the same notification slot.
  final int id;
  final String title;
  final String body;
  final DateTime when;

  const Reminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });
}

/// Returns the next occurrence (month/day) of [isoDate] on or after [from].
///
/// [isoDate] is `yyyy-MM-dd`. The returned date carries the upcoming year,
/// the source month and day, at midnight local time. Feb-29 source dates fall
/// back to Feb-28 in non-leap years. Returns null if [isoDate] can't be parsed.
DateTime? nextOccurrence(String isoDate, DateTime from) {
  final src = DateTime.tryParse(isoDate);
  if (src == null) return null;

  final fromDay = DateTime(from.year, from.month, from.day);

  DateTime build(int year) {
    var month = src.month;
    var day = src.day;
    // Clamp Feb-29 to Feb-28 in non-leap years.
    if (month == 2 && day == 29 && !_isLeap(year)) day = 28;
    return DateTime(year, month, day);
  }

  var candidate = build(from.year);
  if (candidate.isBefore(fromDay)) candidate = build(from.year + 1);
  return candidate;
}

bool _isLeap(int year) =>
    (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

/// Builds the list of upcoming reminders within [withinDays] of [from],
/// derived from living people's birthdays and `marriage` events.
///
/// Pure and deterministic — drives both the Settings "upcoming" preview and
/// the notification scheduler, and is what the unit tests exercise.
List<Reminder> upcomingReminders({
  required List<Person> people,
  required List<LifeEvent> events,
  required DateTime from,
  int withinDays = 365,
}) {
  final horizon = DateTime(from.year, from.month, from.day)
      .add(Duration(days: withinDays));
  final out = <Reminder>[];

  for (final p in people) {
    if (!p.isLiving) continue;
    if (p.birthDate == null) continue;
    final when = nextOccurrence(p.birthDate!, from);
    if (when == null || when.isAfter(horizon)) continue;
    final age = when.year - DateTime.parse(p.birthDate!).year;
    out.add(Reminder(
      id: _slot('bday', p.id),
      title: '🎂 ${p.displayName}’s birthday',
      body: age > 0 ? 'Turns $age today' : 'Birthday today',
      when: when,
    ));
  }

  final peopleById = {for (final p in people) p.id: p};
  for (final e in events) {
    if (e.type != 'marriage' || e.date == null) continue;
    final owner = peopleById[e.personId];
    if (owner == null || !owner.isLiving) continue;
    final when = nextOccurrence(e.date!, from);
    if (when == null || when.isAfter(horizon)) continue;
    final years = when.year - DateTime.parse(e.date!).year;
    out.add(Reminder(
      id: _slot('anniv', e.id),
      title: '💍 ${owner.displayName}’s anniversary',
      body: years > 0 ? '$years years' : 'Anniversary today',
      when: when,
    ));
  }

  out.sort((a, b) => a.when.compareTo(b.when));
  return out;
}

/// Deterministic, collision-resistant notification id from a kind + entity id.
int _slot(String kind, String entityId) {
  final h = '$kind:$entityId'.hashCode;
  return h & 0x7fffffff; // keep positive, within 32-bit
}
