import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A utility class for retrieving user documents from Firestore.
class UserUtil {
  static Stream<DocumentSnapshot<Map<String, dynamic>>> usersStream() =>
      FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.email)
          .snapshots();

  /// Retrieves the user documents from Firestore.
  ///
  /// Returns a [Future] that completes with a [Map] containing the user data.
  static Future<Map<String, dynamic>> getUserDocuments() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get()
        .then((DocumentSnapshot snapshot) {
      return snapshot.data() as Map<String, dynamic>;
    });
  }

  static Future<Map<String, dynamic>> getUserDocumentsFromCache() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get(const GetOptions(source: Source.cache))
        .then((DocumentSnapshot snapshot) {
      return snapshot.data() as Map<String, dynamic>;
    });
  }

  static Future<dynamic> getFieldFromCache(String fieldName) async {
    return await getUserDocumentsFromCache()
        .then((Map<String, dynamic> data) => data['name']);
  }

  /// Reads a field in the user documents from Firestore and creates the field if it doesn't exist.
  ///
  /// [field] is the name of the field to read/create.
  ///
  /// Returns a [Future] that completes with the value of the field.
  static Future<dynamic> readOrCreateField(
    String field,
    dynamic defaultValue,
  ) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);

    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();

    if (userData != null && userData.containsKey(field)) {
      return userData[field];
    } else {
      await userDocRef.set({field: defaultValue}, SetOptions(merge: true));
      return defaultValue;
    }
  }

  static Future<dynamic> readField(
    String field,
  ) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);

    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();

    return userData == null ? null : userData[field];
  }

  static Future<dynamic> readOrCreateFieldFromStream(
    String field,
    dynamic defaultValue,
  ) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);
    final latestData = await usersStream().first;
    if (latestData.data() != null && latestData.data()!.containsKey(field)) {
      return latestData[field];
    } else {
      userDocRef.set({field: defaultValue}, SetOptions(merge: true));
      return defaultValue;
    }
  }

  static Future<dynamic> readFromStream(
    String field,
  ) async {
    final latestData = await usersStream().first;

    return latestData[field];
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
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);

    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();

    if (userData != null && userData.containsKey(jsonPath)) {
      final currentData = userData[jsonPath] as Map<String, dynamic>;
      final modifiedData = modifier(currentData);
      await userDocRef.set({jsonPath: modifiedData}, SetOptions(merge: true));
      return modifiedData;
    } else {
      final emptyData = modifier({});
      await userDocRef.set({jsonPath: emptyData}, SetOptions(merge: true));
      return emptyData;
    }
  }

  static Future<void> modifyBalance(int amount) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);

    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();

    if (userData != null && userData.containsKey('balance')) {
      final currentBalance = userData['balance'] as int;
      final modifiedBalance = currentBalance + amount;
      await userDocRef
          .set({'balance': modifiedBalance}, SetOptions(merge: true));
    } else {
      await userDocRef.set({'balance': amount}, SetOptions(merge: true));
    }
  }

  static Future<Map<String, dynamic>?> fetchLatestTransaction() async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);

    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();

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

  /// Fetches the latest spending from the user.
  ///
  /// Returns a [Future] that completes with a [Map] containing the spending details.
  /// The spending details are represented as key-value pairs, where the key is a [String]
  /// representing the spending category and the value is an [int] representing the amount spent.
  ///
  /// The function internally checks the current date and retrieves the spending details.
  /// If the total spent amount is zero, the function waits indefinitely until the amount is updated.
  ///
  /// Example usage:
  /// ```dart
  /// final spending = await UserUtil.fetchLatestSpending();
  /// print(spending);
  /// ```
  // static Future<Map<String, int>?> fetchLatestSpending() async {
  //   final today = DateTime.now();
  //   int totalSpent = 0;
  //   while (totalSpent == 0) {}
  // }

  static Future<int> fetchTotalSpent([DateTime? date]) async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);

    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();

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
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.email);

    final userDocSnapshot = await userDocRef.get();
    final userData = userDocSnapshot.data();

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
}
