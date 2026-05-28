import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';

void main() => runApp(const ProviderScope(child: HeirloomApp()));

class HeirloomApp extends StatelessWidget {
  const HeirloomApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Heirloom',
        debugShowCheckedModeBanner: false,
        theme: heirloomTheme(),
        home: const Scaffold(body: Center(child: Text('Heirloom'))),
      );
}
