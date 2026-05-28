import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';
import 'repository.dart';

class SqfliteFamilyRepository implements FamilyRepository {
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  @override
  Future<void> init() async {
    if (_db != null) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'heirloom.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE people (
            id TEXT PRIMARY KEY,
            displayName TEXT NOT NULL,
            given TEXT,
            family TEXT,
            gender TEXT,
            birthDate TEXT,
            deathDate TEXT,
            isLiving INTEGER NOT NULL DEFAULT 1,
            photoPath TEXT,
            bio TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE relationships (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            personA TEXT NOT NULL,
            personB TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE events (
            id TEXT PRIMARY KEY,
            personId TEXT NOT NULL,
            type TEXT NOT NULL,
            date TEXT,
            place TEXT,
            note TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE stories (
            id TEXT PRIMARY KEY,
            personId TEXT NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE media (
            id TEXT PRIMARY KEY,
            personId TEXT NOT NULL,
            filePath TEXT NOT NULL,
            caption TEXT
          )
        ''');
      },
    );
  }

  // ── People ────────────────────────────────────────────────────────────────

  @override
  Future<List<Person>> allPeople() async {
    final db = await _database;
    final rows = await db.query('people');
    return rows.map(Person.fromMap).toList();
  }

  @override
  Future<Person?> getPerson(String id) async {
    final db = await _database;
    final rows = await db.query('people', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Person.fromMap(rows.first);
  }

  @override
  Future<void> upsertPerson(Person p) async {
    final db = await _database;
    await db.insert(
      'people',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deletePerson(String id) async {
    final db = await _database;
    await db.delete('people', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'relationships',
      where: 'personA = ? OR personB = ?',
      whereArgs: [id, id],
    );
  }

  // ── Relationships ─────────────────────────────────────────────────────────

  @override
  Future<List<Relationship>> allRelationships() async {
    final db = await _database;
    final rows = await db.query('relationships');
    return rows.map(Relationship.fromMap).toList();
  }

  @override
  Future<void> addRelationship(Relationship r) async {
    final db = await _database;
    await db.insert(
      'relationships',
      r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteRelationship(String id) async {
    final db = await _database;
    await db.delete('relationships', where: 'id = ?', whereArgs: [id]);
  }

  // ── Graph queries ─────────────────────────────────────────────────────────

  @override
  Future<List<Person>> parentsOf(String id) async {
    final db = await _database;
    // relationships where type='parentChild' AND personB=id → fetch personA
    final rels = await db.query(
      'relationships',
      where: "type = 'parentChild' AND personB = ?",
      whereArgs: [id],
    );
    final result = <Person>[];
    for (final r in rels) {
      final person = await getPerson(r['personA'] as String);
      if (person != null) result.add(person);
    }
    return result;
  }

  @override
  Future<List<Person>> childrenOf(String id) async {
    final db = await _database;
    // relationships where type='parentChild' AND personA=id → fetch personB
    final rels = await db.query(
      'relationships',
      where: "type = 'parentChild' AND personA = ?",
      whereArgs: [id],
    );
    final result = <Person>[];
    for (final r in rels) {
      final person = await getPerson(r['personB'] as String);
      if (person != null) result.add(person);
    }
    return result;
  }

  @override
  Future<List<Person>> spousesOf(String id) async {
    final db = await _database;
    // type='spouse' and either side
    final rels = await db.query(
      'relationships',
      where: "type = 'spouse' AND (personA = ? OR personB = ?)",
      whereArgs: [id, id],
    );
    final result = <Person>[];
    for (final r in rels) {
      final otherId =
          (r['personA'] as String) == id ? r['personB'] as String : r['personA'] as String;
      final person = await getPerson(otherId);
      if (person != null) result.add(person);
    }
    return result;
  }

  @override
  Future<List<Person>> siblingsOf(String id) async {
    final parents = await parentsOf(id);
    final sibs = <String, Person>{};
    for (final parent in parents) {
      final children = await childrenOf(parent.id);
      for (final child in children) {
        if (child.id != id) sibs[child.id] = child;
      }
    }
    return sibs.values.toList();
  }

  // ── Life Events ───────────────────────────────────────────────────────────

  @override
  Future<List<LifeEvent>> eventsOf(String id) async {
    final db = await _database;
    final rows =
        await db.query('events', where: 'personId = ?', whereArgs: [id]);
    return rows.map(LifeEvent.fromMap).toList();
  }

  @override
  Future<void> upsertEvent(LifeEvent e) async {
    final db = await _database;
    await db.insert(
      'events',
      e.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteEvent(String id) async {
    final db = await _database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // ── Stories ───────────────────────────────────────────────────────────────

  @override
  Future<List<Story>> storiesOf(String id) async {
    final db = await _database;
    final rows =
        await db.query('stories', where: 'personId = ?', whereArgs: [id]);
    return rows.map(Story.fromMap).toList();
  }

  @override
  Future<void> upsertStory(Story s) async {
    final db = await _database;
    await db.insert(
      'stories',
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteStory(String id) async {
    final db = await _database;
    await db.delete('stories', where: 'id = ?', whereArgs: [id]);
  }

  // ── Media ─────────────────────────────────────────────────────────────────

  @override
  Future<List<MediaItem>> mediaOf(String id) async {
    final db = await _database;
    final rows =
        await db.query('media', where: 'personId = ?', whereArgs: [id]);
    return rows.map(MediaItem.fromMap).toList();
  }

  @override
  Future<void> addMedia(MediaItem m) async {
    final db = await _database;
    await db.insert(
      'media',
      m.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteMedia(String id) async {
    final db = await _database;
    await db.delete('media', where: 'id = ?', whereArgs: [id]);
  }
}
