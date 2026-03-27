import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';
import '../theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await ThemeController.loadTheme();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool _isDesktopOrWeb(BuildContext context) {
    if (kIsWeb) return true;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeNotifier,
      builder: (_, themeMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MyTheme.lightTheme,
          darkTheme: MyTheme.darkTheme,
          themeMode: themeMode, // 👈 controlled by ThemeController
          builder: (context, child) {
            final isDesktop =
                _isDesktopOrWeb(context) ||
                MediaQuery.of(context).size.width >= 900;

            if (isDesktop) {
              // ✅ Desktop/Web — full width, no text scale constraint
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: child!,
                ),
              );
            }

            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(0.8), // 🔥 fixed scale
              ),
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 500) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: child,
                        ),
                      );
                    } else {
                      return child!;
                    }
                  },
                ),
              ),
            );
          },
          home: SplashScreen(
            nextScreen: const LoginScreen(),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }
}
