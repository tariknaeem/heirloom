import 'dart:io';

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../theme.dart';

/// A tappable, fixed-size person card.
///
/// Single tap → [onTap] (re-focus in tree).
/// The "open" icon button in the top-right corner → [onOpenProfile].
class PersonCard extends StatelessWidget {
  final Person person;
  final double width;
  final double height;
  final bool isFocused;
  final VoidCallback? onTap;
  final VoidCallback? onOpenProfile;

  const PersonCard({
    super.key,
    required this.person,
    this.width = 150,
    this.height = 84,
    this.isFocused = false,
    this.onTap,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: isFocused ? kAccent : kLine,
            width: isFocused ? 2 : 1,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: kAccent.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            _buildAvatar(),
            const SizedBox(width: 10),
            Expanded(child: _buildText()),
            _buildOpenButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = _initials(person.displayName);
    final hasPhoto =
        person.photoPath != null && person.photoPath!.isNotEmpty;

    return CircleAvatar(
      radius: 22,
      backgroundColor: kAccent.withValues(alpha: 0.15),
      backgroundImage:
          hasPhoto ? FileImage(File(person.photoPath!)) : null,
      child: hasPhoto
          ? null
          : Text(
              initials,
              style: const TextStyle(
                color: kAccent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
    );
  }

  Widget _buildText() {
    final birthYear = _yearFromDate(person.birthDate);
    final deathYear = _yearFromDate(person.deathDate);
    final hasYears = birthYear != null || deathYear != null;
    final subtitle = hasYears
        ? '${birthYear ?? '?'} – ${deathYear ?? (person.isLiving ? '' : '?')}'
            .trim()
            .replaceAll(RegExp(r'\s*–\s*$'), '')
        : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          person.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: kInk,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kMuted,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOpenButton() {
    if (onOpenProfile == null) return const SizedBox(width: 6);
    return SizedBox(
      width: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: const Icon(Icons.open_in_new_rounded, color: kMuted),
        onPressed: onOpenProfile,
        tooltip: 'Open profile',
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String? _yearFromDate(String? date) {
    if (date == null || date.isEmpty) return null;
    return date.split('-').first;
  }
}
