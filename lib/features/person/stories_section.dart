import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import 'profile_widgets.dart';

/// Profile sub-section: a person's written stories/memories.
class StoriesSection extends ConsumerWidget {
  final String personId;

  const StoriesSection({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    ref.watch(dataVersionProvider);

    return FutureBuilder<List<Story>>(
      future: repo.storiesOf(personId),
      builder: (context, snap) {
        final stories = [...?snap.data]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Stories',
              onAdd: () => _openEditor(context, ref),
            ),
            const SizedBox(height: 12),
            if (stories.isEmpty)
              const EmptyHint('No stories yet — capture a memory or anecdote.')
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kLine),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < stories.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: kLine),
                      ListTile(
                        title: Text(
                          stories[i].title,
                          style: const TextStyle(
                              color: kInk, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          stories[i].body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kMuted, fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: kMuted),
                        onTap: () =>
                            _openEditor(context, ref, existing: stories[i]),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, {Story? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryEditorScreen(personId: personId, existing: existing),
      ),
    );
  }
}

class StoryEditorScreen extends ConsumerStatefulWidget {
  final String personId;
  final Story? existing;

  const StoryEditorScreen({super.key, required this.personId, this.existing});

  @override
  ConsumerState<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends ConsumerState<StoryEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _body = TextEditingController(text: widget.existing?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A title is required.')),
      );
      return;
    }
    final repo = ref.read(repositoryProvider);
    await repo.upsertStory(Story(
      id: widget.existing?.id ?? const Uuid().v4(),
      personId: widget.personId,
      title: _title.text.trim(),
      body: _body.text.trim(),
      createdAt: widget.existing?.createdAt ??
          DateTime.now().millisecondsSinceEpoch,
    ));
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteStory(widget.existing!.id);
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        iconTheme: const IconThemeData(color: kInk),
        title: Text(widget.existing == null ? 'New story' : 'Edit story'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            style: const TextStyle(
                color: kInk, fontSize: 20, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
            ),
          ),
          const Divider(color: kLine),
          TextField(
            controller: _body,
            maxLines: null,
            minLines: 8,
            style: const TextStyle(color: kInk, fontSize: 16, height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Write the story…',
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
