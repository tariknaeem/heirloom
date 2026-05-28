import 'package:flutter_test/flutter_test.dart';
import 'package:heirloom/export/export_service.dart';
import 'package:heirloom/models.dart';

void main() {
  final people = [
    const Person(
      id: 'living',
      displayName: 'Liv Ing',
      birthDate: '1990-01-01',
      bio: 'private bio',
      isLiving: true,
    ),
    const Person(
      id: 'gone',
      displayName: 'De Ceased',
      birthDate: '1900-01-01',
      deathDate: '1980-01-01',
      bio: 'public history',
      isLiving: false,
    ),
  ];
  final events = [
    const LifeEvent(id: 'e1', personId: 'living', type: 'marriage', date: '2015-05-05'),
    const LifeEvent(id: 'e2', personId: 'gone', type: 'birth', date: '1900-01-01'),
  ];
  final stories = [
    const Story(id: 's1', personId: 'living', title: 'Secret', body: 'x', createdAt: 1),
    const Story(id: 's2', personId: 'gone', title: 'Legacy', body: 'y', createdAt: 2),
  ];
  final media = [
    const MediaItem(id: 'm1', personId: 'living', filePath: '/p/a.jpg'),
    const MediaItem(id: 'm2', personId: 'gone', filePath: '/p/b.jpg'),
  ];

  Map<String, Object?> build(bool hide) => ExportService.buildDocument(
        people: people,
        relationships: const [],
        events: events,
        stories: stories,
        media: media,
        hideLivingDetails: hide,
      );

  test('full export keeps everyone and all details', () {
    final doc = build(false);
    expect(doc['format'], 'heirloom-tree');
    expect((doc['people'] as List), hasLength(2));
    expect((doc['events'] as List), hasLength(2));
    expect((doc['stories'] as List), hasLength(2));
    expect((doc['media'] as List), hasLength(2));

    final liv = (doc['people'] as List)
        .cast<Map>()
        .firstWhere((m) => m['id'] == 'living');
    expect(liv['bio'], 'private bio');
  });

  test('redacted export hides living details but keeps names + structure', () {
    final doc = build(true);
    final livedPeople = (doc['people'] as List).cast<Map>();

    final liv = livedPeople.firstWhere((m) => m['id'] == 'living');
    expect(liv['displayName'], 'Liv Ing'); // name preserved
    expect(liv['redacted'], true);
    expect(liv.containsKey('bio'), isFalse); // private fields dropped
    expect(liv.containsKey('birthDate'), isFalse);

    final gone = livedPeople.firstWhere((m) => m['id'] == 'gone');
    expect(gone['bio'], 'public history'); // deceased kept fully

    // Living person's events/stories/media are excluded entirely.
    expect((doc['events'] as List), hasLength(1));
    expect((doc['stories'] as List), hasLength(1));
    expect((doc['media'] as List), hasLength(1));
    expect((doc['events'] as List).cast<Map>().single['personId'], 'gone');
  });

  test('media entries reference in-zip basenames, not absolute paths', () {
    final doc = build(false);
    final m = (doc['media'] as List).cast<Map>().first;
    expect(m['file'], anyOf('a.jpg', 'b.jpg'));
    expect(m.containsKey('filePath'), isFalse);
  });
}
