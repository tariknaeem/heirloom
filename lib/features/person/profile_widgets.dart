import 'package:flutter/material.dart';

import '../../theme.dart';

/// Shared header row for profile sub-sections (title + "Add" button).
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final String addLabel;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onAdd,
    this.addLabel = 'Add',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: kInk, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: kAccent, size: 18),
          label: Text(addLabel, style: const TextStyle(color: kAccent)),
        ),
      ],
    );
  }
}

/// Bordered "nothing here yet" hint card.
class EmptyHint extends StatelessWidget {
  final String text;
  const EmptyHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kLine),
        ),
        child: Text(text, style: const TextStyle(color: kMuted, fontSize: 14)),
      );
}
