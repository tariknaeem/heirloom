// Widget smoke tests for the app shell (onboarding ⇄ tree).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heirloom/features/home/home_shell.dart';
import 'package:heirloom/models.dart';
import 'package:heirloom/providers.dart';
import 'package:heirloom/repository.dart';
import 'package:heirloom/theme.dart';

Widget _app(FamilyRepository repo) => ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: heirloomTheme(), home: const HomeShell()),
    );

void main() {
  testWidgets('empty repo shows onboarding', (tester) async {
    await tester.pumpWidget(_app(InMemoryFamilyRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Heirloom'), findsOneWidget);
    expect(find.text('Create your profile'), findsOneWidget);
  });

  testWidgets('non-empty repo shows the family tree', (tester) async {
    final repo = InMemoryFamilyRepository();
    await repo.upsertPerson(
      const Person(id: 'me', displayName: 'Me'),
    );

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Heirloom'), findsNothing);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Add person'), findsOneWidget);
  });
}
