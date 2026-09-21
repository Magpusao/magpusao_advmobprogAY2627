// packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// screens
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';

// models
import 'models/user.dart';

// providers
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) async {
    await dotenv.load(fileName: 'assets/.env');
    runApp(const MagpusaoAdvMobProg());
  });
}

class MagpusaoAdvMobProg extends StatelessWidget {
  const MagpusaoAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'Chiikawa Shop',
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/signin': (context) => const SignInScreen(),
              // Enhancement 3: Keep theme controls on a dedicated route.
              '/settings': (context) => const SettingsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/home') {
                final arguments = settings.arguments;
                final user = switch (arguments) {
                  User value => value,
                  Map<String, dynamic> value => User.fromJson(value),
                  _ => const User.guest(),
                };
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => HomeScreen(user: user),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
