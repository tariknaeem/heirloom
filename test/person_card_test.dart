import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heirloom/features/tree/person_card.dart';
import 'package:heirloom/models.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('photoless card shows an initials thumbnail', (tester) async {
    await tester.pumpWidget(_host(
      const PersonCard(person: Person(id: 'a', displayName: 'Ada Byron')),
    ));

    // Rounded thumbnail container is present, with initials fallback.
    expect(find.byType(ClipRRect), findsWidgets);
    expect(find.text('AB'), findsOneWidget);
    expect(find.text('Ada Byron'), findsOneWidget);
  });

  testWidgets('birth–death years render as the subtitle', (tester) async {
    await tester.pumpWidget(_host(
      const PersonCard(
        person: Person(
          id: 'a',
          displayName: 'Ada',
          birthDate: '1815-12-10',
          deathDate: '1852-11-27',
          isLiving: false,
        ),
      ),
    ));

    expect(find.text('1815 – 1852'), findsOneWidget);
  });
}
