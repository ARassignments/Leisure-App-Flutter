import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColor.white,
        inputDecorationTheme: AppInputDecoration.inputDecorationTheme(false),
        iconTheme: IconThemeData(color: AppColor.neutral_10),
        primaryColor: AppColor.black,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColor.white,
        inputDecorationTheme: AppInputDecoration.inputDecorationTheme(false),
        iconTheme: IconThemeData(color: AppColor.neutral_70),
        primaryColor: AppColor.black,
        // brightness: Brightness.dark,
        // scaffoldBackgroundColor: AppColor.neutral_100,
        // inputDecorationTheme: AppInputDecoration.inputDecorationTheme(true),
      ),
      themeMode: ThemeMode.system,
      // 👇 Wrap all screens with constraints
      builder: (context, child) {
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor, // Apply scaffold background from ThemeData
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
        );
      },

      home: SplashScreen(
        nextScreen: const LoginScreen(),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
