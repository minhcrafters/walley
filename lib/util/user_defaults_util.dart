import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDefaultsUtil {
  static SharedPreferencesWithCache? preferences;

  static Future<void> initialize() async {
    preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
  }

  static Widget buildWidgetWithPreference(
    String preferenceName,
    Future<dynamic> preferenceValue,
    Widget Function(BuildContext, AsyncSnapshot<dynamic>) builder,
  ) {
    return FutureBuilder(
      future: preferenceValue,
      builder: (_, data) {
        return FutureBuilder(
          future: UserDefaultsUtil.preferences!
              .setString(preferenceName, data.data.toString()),
          builder: (_, __) {
            return builder(_, data);
          },
        );
      },
    );
  }
}
