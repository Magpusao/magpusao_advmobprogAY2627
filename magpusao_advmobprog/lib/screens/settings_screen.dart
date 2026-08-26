import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // Enhancement 3: The dark/light mode control is kept on this dedicated
      // settings page instead of being mixed into the product list screen.
      body: SwitchListTile(
        secondary: Icon(
          themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
        ),
        title: const Text('Dark mode'),
        subtitle: const Text('Use the dark theme throughout the app'),
        value: themeProvider.isDark,
        onChanged: (_) => themeProvider.toggleTheme(),
      ),
    );
  }
}
