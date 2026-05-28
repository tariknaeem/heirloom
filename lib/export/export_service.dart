import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../repository.dart';

/// Builds the portable tree document (JSON) and, separately, zips it together
/// with referenced image files for sharing.
///
/// The JSON shape is the export format — versioned so a future importer can
/// evolve. The [hideLivingDetails] flag redacts private fields for living
/// people (bio, dates, notes, stories) while preserving names + structure so
/// the shared tree is still legible without leaking living relatives' data.
class ExportService {
  static const int formatVersion = 1;

  /// Pure: assemble the export document from already-loaded data.
  static Map<String, Object?> buildDocument({
    required List<Person> people,
    required List<Relationship> relationships,
    required List<LifeEvent> events,
    required List<Story> stories,
    required List<MediaItem> media,
    required bool hideLivingDetails,
  }) {
    final living = {for (final p in people) p.id: p.isLiving};
    bool redact(String personId) =>
        hideLivingDetails && (living[personId] ?? false);

    return {
      'format': 'heirloom-tree',
      'version': formatVersion,
      'hideLivingDetails': hideLivingDetails,
      'people': [
        for (final p in people)
          redact(p.id)
              ? {
                  'id': p.id,
                  'displayName': p.displayName,
                  'isLiving': true,
                  'redacted': true,
                }
              : p.toMap(),
      ],
      'relationships': [for (final r in relationships) r.toMap()],
      'events': [
        for (final e in events)
          if (!redact(e.personId)) e.toMap(),
      ],
      'stories': [
        for (final s in stories)
          if (!redact(s.personId)) s.toMap(),
      ],
      // Media metadata only references the in-zip basename, not the full path.
      'media': [
        for (final m in media)
          if (!redact(m.personId))
            {
              'id': m.id,
              'personId': m.personId,
              'file': p.basename(m.filePath),
              'caption': m.caption,
            },
      ],
    };
  }

  /// Gathers everything from [repo], builds the document, zips it with the
  /// (non-redacted) referenced images, and returns the written zip file.
  static Future<File> writeZip(
    FamilyRepository repo, {
    required bool hideLivingDetails,
  }) async {
    final people = await repo.allPeople();
    final relationships = await repo.allRelationships();

    final events = <LifeEvent>[];
    final stories = <Story>[];
    final media = <MediaItem>[];
    for (final person in people) {
      events.addAll(await repo.eventsOf(person.id));
      stories.addAll(await repo.storiesOf(person.id));
      media.addAll(await repo.mediaOf(person.id));
    }

    final living = {for (final p in people) p.id: p.isLiving};
    bool included(MediaItem m) =>
        !(hideLivingDetails && (living[m.personId] ?? false));

    final doc = buildDocument(
      people: people,
      relationships: relationships,
      events: events,
      stories: stories,
      media: media,
      hideLivingDetails: hideLivingDetails,
    );

    final archive = Archive();
    final jsonBytes =
        utf8.encode(const JsonEncoder.withIndent('  ').convert(doc));
    archive.addFile(ArchiveFile('family.json', jsonBytes.length, jsonBytes));

    // Person hero photos + gallery media that survived redaction.
    final seen = <String>{};
    void addImage(String? path) {
      if (path == null) return;
      final file = File(path);
      if (!file.existsSync()) return;
      final name = 'images/${p.basename(path)}';
      if (!seen.add(name)) return;
      final bytes = file.readAsBytesSync();
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    for (final person in people) {
      if (hideLivingDetails && person.isLiving) continue;
      addImage(person.photoPath);
    }
    for (final m in media.where(included)) {
      addImage(m.filePath);
    }

    final tmpDir = await getTemporaryDirectory();
    final outPath = p.join(tmpDir.path, 'heirloom-tree.zip');
    final encoded = ZipEncoder().encode(archive)!;
    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded, flush: true);
    return outFile;
  }

  /// Builds the zip and opens the system share sheet.
  static Future<void> shareTree(
    FamilyRepository repo, {
    required bool hideLivingDetails,
  }) async {
    final zip = await writeZip(repo, hideLivingDetails: hideLivingDetails);
    await Share.shareXFiles(
      [XFile(zip.path, mimeType: 'application/zip')],
      subject: 'My Heirloom family tree',
    );
  }
}
