import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:walley/impl/ui/abstract_walley_page.dart';
import 'package:walley/impl/ui/home/impl/balance_widget.dart';
import 'package:walley/impl/ui/home/impl/total_spent_widget.dart';
import 'package:walley/util/time_util.dart';
import 'package:walley/util/user_util.dart';

class HomePage extends StatefulWidget implements AbstractWalleyPage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  @override
  String getName() => "Walley";
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserUtil.getSessionUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        final name = user?['name'] ?? '';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  TimeUtil.ofFormat("EEEE, LLLL d"),
                  style: const TextStyle(
                    fontFamily: "SF Pro Display",
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "$name's Wallet",
                  style: TextStyle(
                    fontFamily: "SF Pro Display",
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                // ignore: prefer_const_constructors
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BalanceWidget(),
                    const SizedBox(width: 15),
                    TotalSpentWidget(),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Row(
                children: [
                  /*Expanded(
                child: ElevatedButton(
                  onPressed: () => {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.add),
                      SizedBox(width: 10),
                      Text(
                        "Deposit",
                        style: TextStyle(
                          fontFamily: "SF Pro Display",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => {},
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.minus),
                      SizedBox(width: 10),
                      Text(
                        "Expend",
                        style: TextStyle(
                          fontFamily: "SF Pro Display",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),*/
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 2,
                  ),
                  const Column(
                    children: [
                      SizedBox(
                        height: 1,
                      ),
                      Icon(
                        Iconsax.bookmark,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Lesson Progress",
                      style: TextStyle(
                        fontFamily: "SF Pro Display",
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Icon(
                    Icons.ios_share,
                    size: 15,
                    color: Theme.of(context).hintColor.withAlpha(120),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).hoverColor,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: const Placeholder(),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 2,
                  ),
                  const Column(
                    children: [
                      SizedBox(
                        height: 1,
                      ),
                      Icon(
                        Iconsax.note_1,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      "Your Financial Tracker",
                      style: TextStyle(
                        fontFamily: "SF Pro Display",
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Icon(
                    Icons.ios_share,
                    size: 15,
                    color: Theme.of(context).hintColor.withAlpha(120),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).hoverColor,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: const Placeholder(),
              ),
            ],
          ),
        );
      },
    );
  }
}
