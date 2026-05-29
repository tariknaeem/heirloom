import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import 'edit_person_screen.dart';
import 'relationship_rules.dart';

// ─── Helper functions ─────────────────────────────────────────────────────────

/// Adds a parent→child link if it is valid. Returns null on success, or a
/// human-readable reason it was rejected (self-link, duplicate, cycle).
Future<String?> addParent(WidgetRef ref, String childId, String parentId) async {
  final repo = ref.read(repositoryProvider);
  final existing = await repo.allRelationships();
  final check = canAddParentChild(parentId, childId, existing);
  if (!check.ok) return check.reason;
  await repo.addRelationship(Relationship(
    id: const Uuid().v4(),
    type: RelType.parentChild,
    personA: parentId,
    personB: childId,
  ));
  ref.read(dataVersionProvider.notifier).state++;
  return null;
}

Future<String?> addChild(WidgetRef ref, String parentId, String childId) async {
  final repo = ref.read(repositoryProvider);
  final existing = await repo.allRelationships();
  final check = canAddParentChild(parentId, childId, existing);
  if (!check.ok) return check.reason;
  await repo.addRelationship(Relationship(
    id: const Uuid().v4(),
    type: RelType.parentChild,
    personA: parentId,
    personB: childId,
  ));
  ref.read(dataVersionProvider.notifier).state++;
  return null;
}

Future<String?> addSpouse(
    WidgetRef ref, String personAId, String personBId) async {
  final repo = ref.read(repositoryProvider);
  final existing = await repo.allRelationships();
  final check = canAddSpouse(personAId, personBId, existing);
  if (!check.ok) return check.reason;
  await repo.addRelationship(Relationship(
    id: const Uuid().v4(),
    type: RelType.spouse,
    personA: personAId,
    personB: personBId,
  ));
  ref.read(dataVersionProvider.notifier).state++;
  return null;
}

// ─── RelationshipPicker bottom sheet ─────────────────────────────────────────

enum _RelKind { parent, child, spouse }

class RelationshipPicker extends ConsumerStatefulWidget {
  final String focusPersonId;

  const RelationshipPicker({super.key, required this.focusPersonId});

  @override
  ConsumerState<RelationshipPicker> createState() => _RelationshipPickerState();
}

class _RelationshipPickerState extends ConsumerState<RelationshipPicker> {
  _RelKind _kind = _RelKind.parent;

  /// Returns null on success or a rejection reason to surface to the user.
  Future<String?> _linkPerson(String otherId) async {
    switch (_kind) {
      case _RelKind.parent:
        return addParent(ref, widget.focusPersonId, otherId);
      case _RelKind.child:
        return addChild(ref, widget.focusPersonId, otherId);
      case _RelKind.spouse:
        return addSpouse(ref, widget.focusPersonId, otherId);
    }
  }

  String _kindLabel(_RelKind k) => switch (k) {
        _RelKind.parent => 'Parent',
        _RelKind.child => 'Child',
        _RelKind.spouse => 'Spouse',
      };

  Widget _avatar(Person p) {
    if (p.photoPath != null) {
      return CircleAvatar(
        backgroundImage: FileImage(File(p.photoPath!)),
      );
    }
    return CircleAvatar(
      backgroundColor: kLine,
      child: Text(
        p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
        style: const TextStyle(color: kInk, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add relative',
                    style: TextStyle(
                      color: kInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Relationship kind toggle
                  Row(
                    children: [
                      for (int i = 0; i < _RelKind.values.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _kind = _RelKind.values[i]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _kind == _RelKind.values[i]
                                    ? kAccent
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(kRadius - 2),
                                border: Border.all(
                                  color: _kind == _RelKind.values[i]
                                      ? kAccent
                                      : kLine,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _kindLabel(_RelKind.values[i]),
                                style: TextStyle(
                                  color: _kind == _RelKind.values[i]
                                      ? Colors.white
                                      : kInk,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: kLine),
            Expanded(
              child: peopleAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (people) {
                  final others = people
                      .where((p) => p.id != widget.focusPersonId)
                      .toList();
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Create new person
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kAccent.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add_outlined,
                              color: kAccent),
                        ),
                        title: const Text(
                          'Create new person',
                          style: TextStyle(
                            color: kAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditPersonScreen(),
                            ),
                          );
                          if (result != true || !context.mounted) return;
                          // Re-read people and find the newest one
                          final allPeople = await ref
                              .read(repositoryProvider)
                              .allPeople();
                          final newPeople = allPeople
                              .where((p) => p.id != widget.focusPersonId)
                              .toList();
                          if (newPeople.isEmpty) return;
                          final err = await _linkPerson(newPeople.last.id);
                          if (!context.mounted) return;
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err)),
                            );
                            return;
                          }
                          Navigator.pop(context);
                        },
                      ),
                      if (others.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 6, 16, 2),
                          child: Text(
                            'Or choose existing',
                            style: TextStyle(color: kMuted, fontSize: 12),
                          ),
                        ),
                      for (final person in others)
                        ListTile(
                          leading: _avatar(person),
                          title: Text(
                            person.displayName,
                            style: const TextStyle(color: kInk),
                          ),
                          subtitle: person.birthDate != null
                              ? Text(
                                  'b. ${person.birthDate!.substring(0, 4)}',
                                  style: const TextStyle(color: kMuted),
                                )
                              : null,
                          onTap: () async {
                            final err = await _linkPerson(person.id);
                            if (!context.mounted) return;
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err)),
                              );
                              return;
                            }
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Convenience function to open the picker ─────────────────────────────────

Future<void> showRelationshipPicker(
  BuildContext context,
  String focusPersonId,
) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: RelationshipPicker(focusPersonId: focusPersonId),
    ),
  );
}
