import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models.dart';
import '../../providers.dart';
import '../../theme.dart';
import 'edit_person_screen.dart';
import 'events_section.dart';
import 'gallery_section.dart';
import 'relationship_picker.dart';
import 'stories_section.dart';

class ProfileScreen extends ConsumerWidget {
  final String personId;

  const ProfileScreen({super.key, required this.personId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    // Watch dataVersion so the screen refreshes after edits/adds.
    ref.watch(dataVersionProvider);

    return FutureBuilder<Person?>(
      future: repo.getPerson(personId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final person = snap.data;
        if (person == null) {
          return Scaffold(
            backgroundColor: kBg,
            appBar: AppBar(
              backgroundColor: kBg,
              elevation: 0,
              iconTheme: const IconThemeData(color: kInk),
            ),
            body: const Center(
              child: Text(
                'Person not found.',
                style: TextStyle(color: kMuted, fontSize: 16),
              ),
            ),
          );
        }
        return _ProfileBody(person: person);
      },
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final Person person;

  const _ProfileBody({required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    ref.watch(dataVersionProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: kBg,
            elevation: 0,
            iconTheme: const IconThemeData(color: kInk),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroPhoto(person: person),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPersonScreen(existing: person),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── Identity section ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.displayName,
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (person.birthDate != null || person.deathDate != null)
                        Text(
                          _dateRange(person),
                          style: const TextStyle(color: kMuted, fontSize: 15),
                        ),
                      const SizedBox(width: 10),
                      _StatusChip(isLiving: person.isLiving),
                    ],
                  ),
                  if (person.bio != null && person.bio!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      person.bio!,
                      style: const TextStyle(color: kInk, fontSize: 15, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Relationships section ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Relationships',
                        style: TextStyle(
                          color: kInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            showRelationshipPicker(context, person.id),
                        icon: const Icon(Icons.add, color: kAccent, size: 18),
                        label: const Text(
                          'Add relative',
                          style: TextStyle(color: kAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RelationshipGroup(
                    label: 'Parents',
                    future: repo.parentsOf(person.id),
                  ),
                  _RelationshipGroup(
                    label: 'Spouses',
                    future: repo.spousesOf(person.id),
                  ),
                  _RelationshipGroup(
                    label: 'Children',
                    future: repo.childrenOf(person.id),
                  ),
                  _RelationshipGroup(
                    label: 'Siblings',
                    future: repo.siblingsOf(person.id),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),

          // ── Timeline · Photos · Stories ─────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                EventsSection(personId: person.id),
                GallerySection(personId: person.id),
                StoriesSection(personId: person.id),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _dateRange(Person p) {
    final birth = p.birthDate != null ? p.birthDate!.substring(0, 4) : '?';
    if (!p.isLiving) {
      final death = p.deathDate != null ? p.deathDate!.substring(0, 4) : '?';
      return '$birth – $death';
    }
    return 'b. $birth';
  }
}

// ── Hero photo widget ─────────────────────────────────────────────────────────

class _HeroPhoto extends StatelessWidget {
  final Person person;

  const _HeroPhoto({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBg,
      child: Center(
        child: person.photoPath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(kRadius * 2),
                child: Image.file(
                  File(person.photoPath!),
                  width: 180,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            : CircleAvatar(
                radius: 80,
                backgroundColor: kLine,
                child: Text(
                  person.displayName.isNotEmpty
                      ? person.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 56,
                    color: kMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isLiving;

  const _StatusChip({required this.isLiving});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isLiving
            ? const Color(0xFFD4EDDA)
            : const Color(0xFFE2E3E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLiving ? 'Living' : 'Deceased',
        style: TextStyle(
          color: isLiving
              ? const Color(0xFF155724)
              : const Color(0xFF495057),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Relationship group ────────────────────────────────────────────────────────

class _RelationshipGroup extends StatelessWidget {
  final String label;
  final Future<List<Person>> future;

  const _RelationshipGroup({required this.label, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Person>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(color: kMuted, fontSize: 14),
                ),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ],
            ),
          );
        }
        final people = snap.data ?? [];
        if (people.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(color: kLine),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < people.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: kLine),
                    _PersonRow(person: people[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

// ── Individual person row in relationship list ────────────────────────────────

class _PersonRow extends StatelessWidget {
  final Person person;

  const _PersonRow({required this.person});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: kLine,
        backgroundImage: person.photoPath != null
            ? FileImage(File(person.photoPath!))
            : null,
        child: person.photoPath == null
            ? Text(
                person.displayName.isNotEmpty
                    ? person.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Text(
        person.displayName,
        style: const TextStyle(color: kInk, fontWeight: FontWeight.w500),
      ),
      subtitle: person.birthDate != null
          ? Text(
              'b. ${person.birthDate!.substring(0, 4)}',
              style: const TextStyle(color: kMuted, fontSize: 13),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: kMuted),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(personId: person.id),
        ),
      ),
    );
  }
}
