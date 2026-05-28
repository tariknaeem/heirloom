import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import 'profile_widgets.dart';

/// Profile sub-section: a horizontal scroll of a person's photos.
class GallerySection extends ConsumerWidget {
  final String personId;

  const GallerySection({super.key, required this.personId});

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);
    final dest = p.join(photosDir.path, '${const Uuid().v4()}${p.extension(picked.path)}');
    await File(picked.path).copy(dest);

    final repo = ref.read(repositoryProvider);
    await repo.addMedia(MediaItem(
      id: const Uuid().v4(),
      personId: personId,
      filePath: dest,
    ));
    ref.read(dataVersionProvider.notifier).state++;
  }

  Future<void> _delete(WidgetRef ref, MediaItem m) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteMedia(m.id);
    final f = File(m.filePath);
    if (f.existsSync()) {
      try {
        f.deleteSync();
      } catch (_) {/* best-effort */}
    }
    ref.read(dataVersionProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    ref.watch(dataVersionProvider);

    return FutureBuilder<List<MediaItem>>(
      future: repo.mediaOf(personId),
      builder: (context, snap) {
        final media = snap.data ?? const <MediaItem>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Photos',
              onAdd: () => _addPhoto(context, ref),
            ),
            const SizedBox(height: 12),
            if (media.isEmpty)
              const EmptyHint('No photos yet — add memories from your gallery.')
            else
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: media.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _Thumb(
                    item: media[i],
                    onView: () => _view(context, ref, media[i]),
                  ),
                ),
              ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  void _view(BuildContext context, WidgetRef ref, MediaItem m) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kRadius),
              child: Image.file(File(m.filePath)),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
                _delete(ref, m);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove photo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onView;

  const _Thumb({required this.item, required this.onView});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadius),
        child: Image.file(
          File(item.filePath),
          width: 120,
          height: 132,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            width: 120,
            height: 132,
            color: kLine,
            child: const Icon(Icons.broken_image_outlined, color: kMuted),
          ),
        ),
      ),
    );
  }
}
