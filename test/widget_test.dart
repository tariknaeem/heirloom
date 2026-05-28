// Widget smoke test — kept minimal since HeirloomApp is a shell placeholder.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:heirloom/main.dart';

void main() {
  testWidgets('HeirloomApp renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HeirloomApp()),
    );
    expect(find.text('Heirloom'), findsOneWidget);
  });
}
