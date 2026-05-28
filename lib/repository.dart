import 'models.dart';

/// Storage-agnostic family data API. Local sqflite impl now; a cloud impl can
/// implement the same interface later (sync-ready).
abstract class FamilyRepository {
  Future<void> init();
  Future<List<Person>> allPeople();
  Future<Person?> getPerson(String id);
  Future<void> upsertPerson(Person p);
  Future<void> deletePerson(String id);
  Future<List<Relationship>> allRelationships();
  Future<void> addRelationship(Relationship r);
  Future<void> deleteRelationship(String id);
  // graph queries
  Future<List<Person>> parentsOf(String id);
  Future<List<Person>> childrenOf(String id);
  Future<List<Person>> spousesOf(String id);
  Future<List<Person>> siblingsOf(String id);
  // events / stories / media
  Future<List<LifeEvent>> eventsOf(String id);
  Future<void> upsertEvent(LifeEvent e);
  Future<void> deleteEvent(String id);
  Future<List<Story>> storiesOf(String id);
  Future<void> upsertStory(Story s);
  Future<void> deleteStory(String id);
  Future<List<MediaItem>> mediaOf(String id);
  Future<void> addMedia(MediaItem m);
  Future<void> deleteMedia(String id);
}

/// In-memory implementation — used by unit tests and as a reference.
class InMemoryFamilyRepository implements FamilyRepository {
  final Map<String, Person> _people = {};
  final Map<String, Relationship> _rels = {};
  final Map<String, LifeEvent> _events = {};
  final Map<String, Story> _stories = {};
  final Map<String, MediaItem> _media = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<Person>> allPeople() async => _people.values.toList();

  @override
  Future<Person?> getPerson(String id) async => _people[id];

  @override
  Future<void> upsertPerson(Person p) async => _people[p.id] = p;

  @override
  Future<void> deletePerson(String id) async {
    _people.remove(id);
    _rels.removeWhere((_, r) => r.personA == id || r.personB == id);
  }

  @override
  Future<List<Relationship>> allRelationships() async =>
      _rels.values.toList();

  @override
  Future<void> addRelationship(Relationship r) async => _rels[r.id] = r;

  @override
  Future<void> deleteRelationship(String id) async => _rels.remove(id);

  List<Relationship> get _rl => _rels.values.toList();

  @override
  Future<List<Person>> parentsOf(String id) async => [
        for (final r in _rl)
          if (r.type == RelType.parentChild &&
              r.personB == id &&
              _people[r.personA] != null)
            _people[r.personA]!
      ];

  @override
  Future<List<Person>> childrenOf(String id) async => [
        for (final r in _rl)
          if (r.type == RelType.parentChild &&
              r.personA == id &&
              _people[r.personB] != null)
            _people[r.personB]!
      ];

  @override
  Future<List<Person>> spousesOf(String id) async => [
        for (final r in _rl)
          if (r.type == RelType.spouse &&
              (r.personA == id || r.personB == id))
            _people[r.personA == id ? r.personB : r.personA]!
      ];

  @override
  Future<List<Person>> siblingsOf(String id) async {
    final parents = await parentsOf(id);
    final sibs = <String, Person>{};
    for (final p in parents) {
      for (final c in await childrenOf(p.id)) {
        if (c.id != id) sibs[c.id] = c;
      }
    }
    return sibs.values.toList();
  }

  @override
  Future<List<LifeEvent>> eventsOf(String id) async =>
      [for (final e in _events.values) if (e.personId == id) e];

  @override
  Future<void> upsertEvent(LifeEvent e) async => _events[e.id] = e;

  @override
  Future<void> deleteEvent(String id) async => _events.remove(id);

  @override
  Future<List<Story>> storiesOf(String id) async =>
      [for (final s in _stories.values) if (s.personId == id) s];

  @override
  Future<void> upsertStory(Story s) async => _stories[s.id] = s;

  @override
  Future<void> deleteStory(String id) async => _stories.remove(id);

  @override
  Future<List<MediaItem>> mediaOf(String id) async =>
      [for (final m in _media.values) if (m.personId == id) m];

  @override
  Future<void> addMedia(MediaItem m) async => _media[m.id] = m;

  @override
  Future<void> deleteMedia(String id) async => _media.remove(id);
}
