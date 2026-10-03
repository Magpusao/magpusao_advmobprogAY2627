import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // Enhancement 3: The dark/light mode control is kept on this dedicated
      // settings page instead of being mixed into the product list screen.
      body: ListView(
        children: [
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
            ),
            title: Text(themeProvider.isDark ? 'Light mode' : 'Dark mode'),
            subtitle: Text(
              themeProvider.isDark
                  ? 'Use the light theme throughout the app'
                  : 'Use the dark theme throughout the app',
            ),
            value: themeProvider.isDark,
            onChanged: themeProvider.setDarkMode,
          ),
          const Divider(),
          ListTile(
            key: const Key('settingsLogoutButton'),
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            subtitle: const Text('Clear your session and return to sign in'),
            onTap: () async {
              await UserService().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/signin',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
