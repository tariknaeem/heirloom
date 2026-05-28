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
import 'person_form.dart';

class EditPersonScreen extends ConsumerStatefulWidget {
  final Person? existing;

  const EditPersonScreen({super.key, this.existing});

  @override
  ConsumerState<EditPersonScreen> createState() => _EditPersonScreenState();
}

class _EditPersonScreenState extends ConsumerState<EditPersonScreen> {
  late PersonDraft _draft;
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _givenCtrl = TextEditingController();
  final _familyCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _draft = PersonDraft.from(widget.existing!);
    } else {
      _draft = PersonDraft();
    }
    _displayNameCtrl.text = _draft.displayName;
    _givenCtrl.text = _draft.given ?? '';
    _familyCtrl.text = _draft.family ?? '';
    _bioCtrl.text = _draft.bio ?? '';
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _givenCtrl.dispose();
    _familyCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

    final ext = p.extension(picked.path);
    final fileName = '${const Uuid().v4()}$ext';
    final destPath = p.join(photosDir.path, fileName);
    await File(picked.path).copy(destPath);

    setState(() {
      _draft.photoPath = destPath;
    });
  }

  Future<void> _pickDate({required bool isBirth}) async {
    final now = DateTime.now();
    final initial = isBirth
        ? (_draft.birthDate != null
            ? DateTime.tryParse(_draft.birthDate!) ?? now
            : now)
        : (_draft.deathDate != null
            ? DateTime.tryParse(_draft.deathDate!) ?? now
            : now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final iso = picked.toIso8601String().substring(0, 10);
    setState(() {
      if (isBirth) {
        _draft.birthDate = iso;
      } else {
        _draft.deathDate = iso;
      }
    });
  }

  Future<void> _save() async {
    _draft.displayName = _displayNameCtrl.text;
    _draft.given = _givenCtrl.text.isEmpty ? null : _givenCtrl.text;
    _draft.family = _familyCtrl.text.isEmpty ? null : _familyCtrl.text;
    _draft.bio = _bioCtrl.text.isEmpty ? null : _bioCtrl.text;

    final error = _draft.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final person = _draft.toPerson(id: widget.existing?.id);
      await repo.upsertPerson(person);
      ref.read(dataVersionProvider.notifier).state++;
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete person?'),
        content: Text(
          'Remove ${widget.existing!.displayName} and all their relationships?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      await repo.deletePerson(widget.existing!.id);
      ref.read(dataVersionProvider.notifier).state++;
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Person' : 'Add Person',
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: kInk),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo avatar
                    Center(
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: kLine,
                          backgroundImage: _draft.photoPath != null
                              ? FileImage(File(_draft.photoPath!))
                              : null,
                          child: _draft.photoPath == null
                              ? const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: kMuted,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Tap to change photo',
                        style: TextStyle(color: kMuted, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Display name (required)
                    _fieldLabel('Display Name *'),
                    _textField(
                      controller: _displayNameCtrl,
                      hint: 'e.g. Jane Doe',
                    ),
                    const SizedBox(height: 16),

                    // Given / family
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Given name'),
                              _textField(
                                controller: _givenCtrl,
                                hint: 'Jane',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Family name'),
                              _textField(
                                controller: _familyCtrl,
                                hint: 'Doe',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    _fieldLabel('Gender'),
                    _genderSelector(),
                    const SizedBox(height: 16),

                    // Is living switch
                    _card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Living',
                            style: TextStyle(
                              color: kInk,
                              fontSize: 16,
                            ),
                          ),
                          Switch(
                            value: _draft.isLiving,
                            activeThumbColor: kAccent,
                            onChanged: (v) => setState(() {
                              _draft.isLiving = v;
                              if (v) _draft.deathDate = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Birth date
                    _fieldLabel('Birth date'),
                    _dateTile(
                      value: _draft.birthDate,
                      hint: 'Select birth date',
                      onTap: () => _pickDate(isBirth: true),
                      onClear: () => setState(() => _draft.birthDate = null),
                    ),
                    const SizedBox(height: 16),

                    // Death date (only when not living)
                    if (!_draft.isLiving) ...[
                      _fieldLabel('Death date'),
                      _dateTile(
                        value: _draft.deathDate,
                        hint: 'Select death date',
                        onTap: () => _pickDate(isBirth: false),
                        onClear: () => setState(() => _draft.deathDate = null),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Bio
                    _fieldLabel('Bio'),
                    _textField(
                      controller: _bioCtrl,
                      hint: 'A short biography…',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccent,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadius),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Save changes' : 'Add person',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: kMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kMuted),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: const BorderSide(color: kLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadius),
            borderSide: const BorderSide(color: kAccent, width: 2),
          ),
        ),
      );

  Widget _genderSelector() {
    final options = ['male', 'female', 'other'];
    final labels = {'male': 'Male', 'female': 'Female', 'other': 'Other'};
    return _card(
      child: Row(
        children: [
          for (final opt in options) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => setState(
                  () => _draft.gender = _draft.gender == opt ? null : opt,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        _draft.gender == opt ? kAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(kRadius - 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[opt]!,
                    style: TextStyle(
                      color: _draft.gender == opt ? Colors.white : kInk,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            if (opt != options.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _dateTile({
    required String? value,
    required String hint,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) =>
      _card(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  value ?? hint,
                  style: TextStyle(
                    color: value != null ? kInk : kMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, color: kMuted, size: 18),
              ),
            if (value == null)
              const Icon(Icons.calendar_today_outlined,
                  color: kMuted, size: 18),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kLine),
        ),
        child: child,
      );
}
