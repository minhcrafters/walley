import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'http://localhost:5000',
  ),
);

class UserUtil {
  static String? sessionToken;
  static Map<String, dynamic>? _cachedSessionUser;

  static void setupDio() {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (sessionToken != null) {
            options.headers['Authorization'] = 'Bearer ${sessionToken!}';
          }
          return handler.next(options);
        },
      ),
    );
  }

  static Future<Map<String, dynamic>?> getSessionUser(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSessionUser != null) return _cachedSessionUser;
    final response = await dio.get('/session/user');
    if (response.statusCode == 200) {
      _cachedSessionUser = response.data;
      return response.data;
    }
    return null;
  }

  /// A utility class for retrieving user documents from Firestore.
  static Future<Map<String, dynamic>?> getUserDocuments() async {
    final user = await getSessionUser();
    if (user == null || user['email'] == null) return null;
    final response = await dio.get('/user', queryParameters: {'email': user['email']});
    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  }

  /// Reads a field in the user documents and creates the field if it doesn't exist.
  ///
  /// [field] is the name of the field to read/create.
  ///
  /// Returns a [Future] that completes with the value of the field.
  static Future<dynamic> readOrCreateField(
    String field,
    dynamic defaultValue,
  ) async {
    final userData = await getUserDocuments();
    if (userData != null && userData.containsKey(field)) {
      return userData[field];
    } else {
      final user = await getSessionUser();
      if (user == null || user['email'] == null) return defaultValue;
      // Create the field with the default value
      await dio.post(
        '/user/update',
        data: jsonEncode({'email': user['email'], field: defaultValue}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return defaultValue;
    }
  }

  static Future<dynamic> readField(
    String field,
  ) async {
    final userData = await getUserDocuments();
    return userData == null ? null : userData[field];
  }

  /// Modifies a JSON document in the database and creates an empty JSON if it doesn't exist.
  ///
  /// [jsonPath] is the path to the JSON document.
  /// [modifier] is a function that takes the current JSON data as input and returns the modified JSON data.
  ///
  /// Returns a [Future] that completes with the modified JSON data.
  static Future<Map<String, dynamic>> modifyJsonDocument(
    String jsonPath,
    Map<String, dynamic> Function(Map<String, dynamic> currentData) modifier,
  ) async {
    final userData = await getUserDocuments();
    if (userData != null && userData.containsKey(jsonPath)) {
      final currentData = userData[jsonPath] as Map<String, dynamic>;
      final modifiedData = modifier(currentData);
      final user = await getSessionUser();
      if (user == null || user['email'] == null) return modifiedData;
      await dio.post(
        '/user/update',
        data: jsonEncode({'email': user['email'], jsonPath: modifiedData}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return modifiedData;
    } else {
      final emptyData = modifier({});
      final user = await getSessionUser();
      if (user == null || user['email'] == null) return emptyData;
      await dio.post(
        '/user/update',
        data: jsonEncode({'email': user['email'], jsonPath: emptyData}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return emptyData;
    }
  }

  static Future<void> modifyBalance(int amount) async {
    final userData = await getUserDocuments();
    final user = await getSessionUser();
    if (user == null || user['email'] == null) return;
    if (userData != null && userData.containsKey('balance')) {
      final currentBalance = userData['balance'] as int;
      final modifiedBalance = currentBalance + amount;
      await dio.post(
        '/user/update',
        data: jsonEncode({'email': user['email'], 'balance': modifiedBalance}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } else {
      await dio.post(
        '/user/update',
        data: jsonEncode({'email': user['email'], 'balance': amount}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    }
  }

  static Future<Map<String, dynamic>?> fetchLatestTransaction() async {
    final userData = await getUserDocuments();
    if (userData != null && userData.containsKey('spendingHistory')) {
      final transactions = userData['spendingHistory'] as Map<String, dynamic>;
      final sortedKeys = transactions.keys.toList()..sort();
      final latestKey = sortedKeys.isNotEmpty ? sortedKeys.last : null;
      return latestKey != null
          ? <String, dynamic>{
              "time": latestKey.toString(),
              "data": transactions[latestKey],
            }
          : null;
    } else {
      return null;
    }
  }

  static Future<int> fetchTotalSpent([DateTime? date]) async {
    final userData = await getUserDocuments();
    if (userData != null && userData.containsKey('spendingHistory')) {
      final transactions = userData['spendingHistory'] as Map<String, dynamic>;
      transactions.removeWhere(
        (key, value) {
          final transactionDate = DateTime.tryParse(key);
          if (transactionDate == null) {
            debugPrint("FormatException: Invalid date format!\nKey: $key");
            return true;
          }
          final comparingDate = date ?? DateTime.now();
          return transactionDate.day != comparingDate.day ||
              transactionDate.month != comparingDate.month ||
              transactionDate.year != comparingDate.year ||
              (int.tryParse(value['amount'].toString()) ?? 0) > 0;
        },
      ); // filter out transactions in other days
      if (transactions.isEmpty) {
        return 0;
      }

      int total = transactions.entries.fold(0,
          (int sum, MapEntry<String, dynamic> entry) {
        int balanceChange =
            (int.tryParse(entry.value['amount'].toString()) ?? 0);
        return sum + balanceChange.abs();
      });
      return total; // return the calculated total
    } else {
      return 0;
    }
  }

  static Future<double> calculateAverageMonthlySpending() async {
    final userData = await getUserDocuments();
    if (userData != null && userData.containsKey('spendingHistory')) {
      final transactions = userData['spendingHistory'] as Map<String, dynamic>;
      final currentDate = DateTime.now();
      final currentMonth = currentDate.month;
      final currentYear = currentDate.year;

      double totalSpending = 0;
      int transactionCount = 0;

      transactions.forEach((key, value) {
        final transactionDate = DateTime.tryParse(key);
        if (transactionDate != null &&
            transactionDate.month == currentMonth &&
            transactionDate.year == currentYear) {
          final amount = value['amount'] as int;
          totalSpending += amount.abs();
          transactionCount++;
        }
      });

      if (transactionCount > 0) {
        return totalSpending / transactionCount;
      } else {
        return 0;
      }
    } else {
      return 0;
    }
  }

  static Future<bool> deleteUser() async {
    final user = await getSessionUser();
    if (user == null || user['email'] == null) return false;
    final response = await dio.post(
      '/user/delete',
      data: jsonEncode({'email': user['email']}),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final response = await dio.get('/user/get_by_id', queryParameters: {'id': id});
    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  }

  static Future<bool> deleteTransaction(int id) async {
    final response = await dio.post(
      '/transaction/delete',
      data: jsonEncode({'id': id}),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateTransaction(
      int id, Map<String, dynamic> fields) async {
    final body = {'id': id, ...fields};
    final response = await dio.post(
      '/transaction/update',
      data: jsonEncode(body),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final response = await dio.get('/transaction/get', queryParameters: {'id': id});
    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getSummary() async {
    final user = await getSessionUser();
    if (user == null || user['email'] == null) return null;
    final response = await dio.get('/summary', queryParameters: {'email': user['email']});
    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  }
}
