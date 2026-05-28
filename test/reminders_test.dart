import 'package:flutter_test/flutter_test.dart';
import 'package:heirloom/features/reminders/reminders.dart';
import 'package:heirloom/models.dart';

void main() {
  group('nextOccurrence', () {
    test('returns later-this-year date when the day is still ahead', () {
      final from = DateTime(2026, 1, 1);
      final next = nextOccurrence('1990-06-15', from);
      expect(next, DateTime(2026, 6, 15));
    });

    test('rolls to next year when the day has already passed', () {
      final from = DateTime(2026, 8, 1);
      final next = nextOccurrence('1990-06-15', from);
      expect(next, DateTime(2027, 6, 15));
    });

    test('treats today as upcoming (not passed)', () {
      final from = DateTime(2026, 6, 15);
      final next = nextOccurrence('1990-06-15', from);
      expect(next, DateTime(2026, 6, 15));
    });

    test('clamps Feb-29 to Feb-28 in a non-leap year', () {
      final from = DateTime(2027, 1, 1); // 2027 is not a leap year
      final next = nextOccurrence('2000-02-29', from);
      expect(next, DateTime(2027, 2, 28));
    });

    test('keeps Feb-29 in a leap year', () {
      final from = DateTime(2028, 1, 1); // 2028 is a leap year
      final next = nextOccurrence('2000-02-29', from);
      expect(next, DateTime(2028, 2, 29));
    });

    test('returns null for an unparseable date', () {
      expect(nextOccurrence('not-a-date', DateTime(2026, 1, 1)), isNull);
    });
  });

  group('upcomingReminders', () {
    final from = DateTime(2026, 1, 1);

    test('includes a living person birthday with correct age', () {
      final people = [
        const Person(id: 'a', displayName: 'Ada', birthDate: '1990-06-15'),
      ];
      final out = upcomingReminders(people: people, events: [], from: from);
      expect(out, hasLength(1));
      expect(out.first.title, contains('Ada'));
      expect(out.first.body, contains('36')); // turns 36 in 2026
      expect(out.first.when, DateTime(2026, 6, 15));
    });

    test('skips deceased people and those without a birth date', () {
      final people = [
        const Person(
            id: 'a', displayName: 'Gone', birthDate: '1900-06-15', isLiving: false),
        const Person(id: 'b', displayName: 'NoDate'),
      ];
      final out = upcomingReminders(people: people, events: [], from: from);
      expect(out, isEmpty);
    });

    test('includes marriage anniversaries for living owners', () {
      final people = [
        const Person(id: 'a', displayName: 'Ada', birthDate: '1990-01-10'),
      ];
      final events = [
        const LifeEvent(
            id: 'e', personId: 'a', type: 'marriage', date: '2010-09-20'),
      ];
      final out = upcomingReminders(people: people, events: events, from: from);
      expect(out.any((r) => r.title.contains('anniversary')), isTrue);
      final anniv = out.firstWhere((r) => r.title.contains('anniversary'));
      expect(anniv.when, DateTime(2026, 9, 20));
    });

    test('respects the horizon window', () {
      final people = [
        const Person(id: 'a', displayName: 'Ada', birthDate: '1990-12-31'),
      ];
      final out = upcomingReminders(
        people: people,
        events: [],
        from: DateTime(2026, 1, 1),
        withinDays: 30,
      );
      expect(out, isEmpty); // Dec 31 is well beyond 30 days
    });

    test('results are sorted by date', () {
      final people = [
        const Person(id: 'a', displayName: 'A', birthDate: '1990-09-01'),
        const Person(id: 'b', displayName: 'B', birthDate: '1990-03-01'),
      ];
      final out = upcomingReminders(people: people, events: [], from: from);
      expect(out.first.when.isBefore(out.last.when), isTrue);
    });
  });
}
