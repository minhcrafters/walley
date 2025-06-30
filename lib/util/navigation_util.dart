import 'package:flutter/material.dart';

class NavigationUtil {
  static void navigateTo(Widget screen, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  static void navigateToWithoutBack(Widget screen, BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (Route<dynamic> route) => false,
    );
  }

  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }
}
