import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:walley/impl/auth/login_screen.dart';
import 'package:walley/impl/ui/abstract_walley_page.dart';
import 'package:walley/util/navigation_util.dart';
import 'package:walley/util/user_util.dart';

class UserPage extends StatelessWidget implements AbstractWalleyPage {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserUtil.getSessionUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        final email = user?['email'] ?? '';
        final name = user?['name'] ?? '';
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 60,
            title: const Text(
              "My Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: AssetImage(
                        'assets/placeholder_avatar.jpg',
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "\nHello, $name!",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Name",
                        style: TextStyle(fontSize: 18),
                      ),
                      Icon(Iconsax.arrow_right),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Username",
                        style: TextStyle(fontSize: 18),
                      ),
                      Icon(Iconsax.arrow_right),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Mail",
                        style: TextStyle(fontSize: 18),
                      ),
                      Icon(Iconsax.arrow_right),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Phone number",
                        style: TextStyle(fontSize: 18),
                      ),
                      Icon(Iconsax.arrow_right),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Social media",
                        style: TextStyle(fontSize: 18),
                      ),
                      Icon(Iconsax.arrow_right),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () => {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: const Text("Log out?"),
                            content: const Text(
                              "You will be redirected to the login screen.",
                            ),
                            actions: [
                              ElevatedButton(
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              ElevatedButton(
                                child: const Text("Log out"),
                                onPressed: () async {
                                  if (context.mounted) {
                                    NavigationUtil.navigateToWithoutBack(
                                      const LoginScreen(),
                                      context,
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Log out",
                          style: TextStyle(fontSize: 18, color: Colors.red),
                        ),
                        Icon(Iconsax.arrow_right),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  String getName() => "User";
}
