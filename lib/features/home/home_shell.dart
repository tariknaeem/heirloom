import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../theme.dart';
import '../person/edit_person_screen.dart';
import '../person/profile_screen.dart';
import '../tree/tree_screen.dart';

/// Decides the app's home: onboarding when there are no people yet, otherwise
/// the family tree. Listens to [peopleProvider] so it switches automatically
/// once the first person is created.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);

    return peopleAsync.when(
      loading: () => const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Could not open your family data.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted),
            ),
          ),
        ),
      ),
      data: (people) {
        if (people.isEmpty) return const _Onboarding();
        return TreeScreen(
          onOpenProfile: (personId) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(personId: personId),
            ),
          ),
        );
      },
    );
  }
}

/// First-run welcome screen — invites the user to create their own profile,
/// which seeds the tree. On save, [peopleProvider] refetches and [HomeShell]
/// swaps to the tree automatically.
class _Onboarding extends StatelessWidget {
  const _Onboarding();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_tree_rounded,
                  size: 72,
                  color: kAccent.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Welcome to Heirloom',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kInk,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Build your family tree, keep photos, stories and '
                  'life events — all on your device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditPersonScreen(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Create your profile'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
