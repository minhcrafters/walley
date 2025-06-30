import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:form_validator/form_validator.dart';
import 'package:walley/root_page.dart';
import 'package:walley/util/navigation_util.dart';
import 'package:walley/impl/auth/register_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:walley/util/user_util.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool passwordHidden = true;

  // Add these widget fields for logo display
  final Widget image =
      SvgPicture.asset('assets/transparent_logo.svg', fit: BoxFit.contain);
  final Widget textLogo =
      SvgPicture.asset('assets/text_logo.svg', fit: BoxFit.contain);

  Future<void> attemptLogin() async {
    if (_form.currentState!.validate()) {
      try {
        final response = await dio.post(
          '/login',
          data: jsonEncode({
            'email': emailController.text,
            'password': passwordController.text,
          }),
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        final data = response.data;
        if (response.statusCode == 200) {
          if (mounted) {
            NavigationUtil.navigateToWithoutBack(const RootPage(), context);
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                content: Text(data['error'] ?? 'Unknown error'),
                title: const Text('Error'),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Text('Login failed: ${e.toString()}'),
              title: const Text('Error'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Column loginSection(BuildContext context, form) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome back",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () => NavigationUtil.navigateTo(
                const RegisterScreen(),
                context,
              ),
              child: Text(
                " Register here.",
                style: TextStyle(
                  fontSize: 14,
                  color: MediaQuery.of(context).platformBrightness ==
                          Brightness.dark
                      ? Colors.blue.shade600
                      : Colors.blue.shade800,
                ),
              ),
            ),
          ],
        ),
        Form(
          key: form,
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: emailController,
                autocorrect: false,
                maxLines: 1,
                validator: ValidationBuilder().email().maxLength(30).build(),
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: passwordController,
                autocorrect: false,
                maxLines: 1,
                obscureText: passwordHidden,
                validator: ValidationBuilder()
                    .minLength(
                      8,
                      "Your password must be at least 8 characters long",
                    )
                    .maxLength(
                      50,
                      "Your password must not exceed 50 characters.",
                    )
                    .build(),
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordHidden ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        passwordHidden = !passwordHidden;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Forgot password?"),
                    ElevatedButton(
                      onPressed: attemptLogin,
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: BorderSide(
                              color: Theme.of(context).hintColor.withAlpha(90),
                            ),
                          ),
                        ),
                      ),
                      child: const Text(
                        "Sign in",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 25, right: 25),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxHeight > 500) {
                // big screen

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: image,
                    ),
                    Expanded(
                      flex: 7,
                      child: loginSection(
                        context,
                        _form,
                      ),
                    ),
                  ],
                );
              } else {
                // small screen

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: textLogo,
                    ),
                    Expanded(
                      flex: 7,
                      child: loginSection(
                        context,
                        _form,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
// Remove or update references to RegisterScreen, image, and textLogo as needed in the UI code.
