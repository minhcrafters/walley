import 'package:flutter/material.dart';
import 'package:walley/gobal.dart';
import 'package:walley/impl/auth/login_screen.dart';
import 'package:walley/util/color_util.dart';
import 'package:walley/util/user_defaults_util.dart';
import 'package:walley/util/user_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserDefaultsUtil.initialize();
  setupDio();

  runApp(const Walley());
}

class Walley extends StatelessWidget {
  const Walley({super.key});

  static const String version = "0.2";
  static const bool beta = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walley',
      theme: ThemeData(
        colorScheme: ColorUtil.getColorScheme(),
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: "SF Pro Display",
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: "SF Pro Display",
      ),
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: GlobalVariable.navState,
    );
  }
}
