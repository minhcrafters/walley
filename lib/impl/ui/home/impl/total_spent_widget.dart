import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:walley/util/finance_util.dart';
import 'package:walley/util/user_defaults_util.dart';
import 'package:walley/util/user_util.dart';

class TotalSpentWidget extends StatelessWidget {
  const TotalSpentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).hoverColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: FutureBuilder(
          future: UserUtil.fetchTotalSpent(),
          builder: (_, todaysTotalSpending) {
            bool fetchingData =
                todaysTotalSpending.connectionState != ConnectionState.done ||
                    todaysTotalSpending.hasError;

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Total Spent ",
                      style: TextStyle(
                        fontFamily: "SF Pro Display",
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    FutureBuilder(
                      future: UserUtil.fetchTotalSpent(
                        DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                      ),
                      builder: (_, yesterdaysTotalSpending) {
                        bool fetchingData =
                            yesterdaysTotalSpending.connectionState !=
                                    ConnectionState.done ||
                                yesterdaysTotalSpending.hasError ||
                                yesterdaysTotalSpending.data == null ||
                                todaysTotalSpending.data == null;

                        bool? cachedComparisonPositive = UserDefaultsUtil
                            .preferences!
                            .getBool("totalSpentYesterdayComparisonPositive");
                        String? cachedComparisonValue = UserDefaultsUtil
                            .preferences!
                            .getString("totalSpentYesterdayComparisonValue");

                        if (cachedComparisonPositive == null ||
                            cachedComparisonValue == "0%") {
                          return const SizedBox.shrink();
                        }

                        if (fetchingData) {
                          return Row(
                            children: [
                              Icon(
                                cachedComparisonPositive
                                    ? Iconsax.arrow_up_3
                                    : Iconsax.arrow_down,
                                size: 13,
                                color:
                                    Theme.of(context).hintColor.withAlpha(120),
                              ),
                              Text(
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                "$cachedComparisonValue%",
                                style: TextStyle(
                                  fontFamily: "SF Pro Display",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .hintColor
                                      .withAlpha(120),
                                ),
                              ),
                            ],
                          );
                        }

                        final today = (todaysTotalSpending.data ?? 0) as num;
                        final yesterday =
                            (yesterdaysTotalSpending.data ?? 0) as num;
                        bool isTodaysSpendingHigher = today > yesterday;
                        double calculatePercentage() {
                          if (today == 0 || yesterday == 0) return 0;
                          return isTodaysSpendingHigher
                              ? (today / yesterday * 100)
                              : (yesterday / today * 100);
                        }

                        double percentage = calculatePercentage();
                        if (percentage == 0) {
                          return const SizedBox.shrink();
                        }
                        UserDefaultsUtil.preferences!.setString(
                          "totalSpentYesterdayComparisonValue",
                          "${percentage.round()}%",
                        );
                        UserDefaultsUtil.preferences!.setBool(
                          "totalSpentYesterdayComparisonPositive",
                          isTodaysSpendingHigher,
                        );
                        return Row(
                          children: [
                            percentage == 0
                                ? const SizedBox.shrink()
                                : Icon(
                                    isTodaysSpendingHigher
                                        ? Iconsax.arrow_up_3
                                        : Iconsax.arrow_down,
                                    size: 13,
                                    color: Theme.of(context)
                                        .hintColor
                                        .withAlpha(120),
                                  ),
                            percentage == 0
                                ? const SizedBox.shrink()
                                : Text(
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.fade,
                                    "$percentage%",
                                    style: TextStyle(
                                      fontFamily: "SF Pro Display",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .hintColor
                                          .withAlpha(120),
                                    ),
                                  ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                fetchingData
                    ? Expanded(
                        flex: 10,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            (UserDefaultsUtil.preferences!
                                        .getString("totalSpentAmount") ??
                                    0)
                                .toString(),
                            style: const TextStyle(
                              height: 0,
                            ),
                          ),
                        ),
                      )
                    : FutureBuilder(
                        future: UserDefaultsUtil.preferences!.setString(
                          "totalSpentAmount",
                          "${FinanceUtil.vnd.format(todaysTotalSpending.data)}₫",
                        ),
                        builder: (_, __) => Expanded(
                          flex: 10,
                          child: FittedBox(
                            child: Text(
                              "${FinanceUtil.vnd.format(todaysTotalSpending.data)}₫",
                              style: const TextStyle(
                                height: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(
                  height: 1,
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 12,
                      color: Theme.of(context).hintColor.withAlpha(120),
                    ),
                    FutureBuilder(
                      future: UserUtil.fetchLatestTransaction(),
                      builder: (_, data) {
                        bool fetchingData =
                            data.connectionState != ConnectionState.done ||
                                data.data == null;
                        if (fetchingData) {
                          return Expanded(
                            child: Text(
                              UserDefaultsUtil.preferences!
                                      .getString("totalSpentHistoryText") ??
                                  "",
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color:
                                    Theme.of(context).hintColor.withAlpha(120),
                                height: 0,
                              ),
                            ),
                          );
                        }
                        int? rawMoneyValue = int.tryParse(
                          data.data!["data"]["amount"].toString(),
                        );
                        String time = "";
                        try {
                          time = DateFormat("jm")
                              .format(DateTime.parse(data.data!["time"]));
                        } catch (_) {}
                        String displayText =
                            " ${rawMoneyValue == null ? "" : "${FinanceUtil.vnd.format(rawMoneyValue)}₫ at"} $time";
                        return FutureBuilder(
                          future: UserDefaultsUtil.preferences!
                              .setString("totalSpentHistoryText", displayText),
                          builder: (_, __) {
                            return Expanded(
                              child: Text(
                                fetchingData
                                    ? UserDefaultsUtil.preferences!
                                        .getString("totalSpentHistoryText")!
                                    : displayText,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .hintColor
                                      .withAlpha(120),
                                  height: 0,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
