import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import 'profile_widgets.dart';

const _eventTypes = <String, (String, IconData)>{
  'birth': ('Birth', Icons.cake_rounded),
  'marriage': ('Marriage', Icons.favorite_rounded),
  'death': ('Death', Icons.local_florist_rounded),
  'custom': ('Custom', Icons.event_note_rounded),
};

/// Profile sub-section: a date-sorted timeline of a person's life events,
/// with an add button. Reads via the repo and refreshes on dataVersion bumps.
class EventsSection extends ConsumerWidget {
  final String personId;

  const EventsSection({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    ref.watch(dataVersionProvider);

    return FutureBuilder<List<LifeEvent>>(
      future: repo.eventsOf(personId),
      builder: (context, snap) {
        final events = [...?snap.data]
          ..sort((a, b) => (a.date ?? '').compareTo(b.date ?? ''));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Timeline',
              onAdd: () => showEventEditor(context, ref, personId: personId),
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const EmptyHint('No events yet — add a birth, marriage, or milestone.')
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kLine),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < events.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: kLine),
                      _EventRow(
                        event: events[i],
                        onTap: () => showEventEditor(context, ref,
                            personId: personId, existing: events[i]),
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
}

class _EventRow extends StatelessWidget {
  final LifeEvent event;
  final VoidCallback onTap;

  const _EventRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = _eventTypes[event.type] ?? _eventTypes['custom']!;
    final subtitle = [
      if (event.date != null) _prettyDate(event.date!),
      if (event.place != null && event.place!.isNotEmpty) event.place,
    ].whereType<String>().join(' · ');

    return ListTile(
      leading: Icon(meta.$2, color: kAccent),
      title: Text(
        event.type == 'custom' && (event.note?.isNotEmpty ?? false)
            ? event.note!
            : meta.$1,
        style: const TextStyle(color: kInk, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, color: kMuted),
      onTap: onTap,
    );
  }
}

String _prettyDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return DateFormat.yMMMMd().format(d);
}

// ── Editor bottom sheet ───────────────────────────────────────────────────────

Future<void> showEventEditor(
  BuildContext context,
  WidgetRef ref, {
  required String personId,
  LifeEvent? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
    ),
    builder: (_) => _EventEditor(personId: personId, existing: existing),
  );
}

class _EventEditor extends ConsumerStatefulWidget {
  final String personId;
  final LifeEvent? existing;

  const _EventEditor({required this.personId, this.existing});

  @override
  ConsumerState<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends ConsumerState<_EventEditor> {
  late String _type;
  String? _date;
  late final TextEditingController _place;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? 'custom';
    _date = widget.existing?.date;
    _place = TextEditingController(text: widget.existing?.place ?? '');
    _note = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date != null ? DateTime.tryParse(_date!) : null,
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked.toIso8601String().substring(0, 10));
    }
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    await repo.upsertEvent(LifeEvent(
      id: widget.existing?.id ?? const Uuid().v4(),
      personId: widget.personId,
      type: _type,
      date: _date,
      place: _place.text.trim().isEmpty ? null : _place.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    ));
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteEvent(widget.existing!.id);
    ref.read(dataVersionProvider.notifier).state++;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Add event' : 'Edit event',
            style: const TextStyle(
                color: kInk, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in _eventTypes.entries)
                ChoiceChip(
                  label: Text(entry.value.$1),
                  selected: _type == entry.key,
                  onSelected: (_) => setState(() => _type = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(_date == null ? 'Pick a date' : _prettyDate(_date!)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _place,
            decoration: const InputDecoration(hintText: 'Place (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(hintText: 'Note (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.existing != null)
                TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              const Spacer(),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}

