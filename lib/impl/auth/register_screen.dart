import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:form_validator/form_validator.dart';
import 'package:walley/root_page.dart';
import 'package:walley/util/navigation_util.dart';
import 'package:walley/util/user_util.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool passwordHidden = true;

  Future<void> attemptRegisterAccount() async {
    if (_form.currentState!.validate()) {
      try {
        final response = await dio.post(
          '/register',
          data: jsonEncode({
            'email': emailController.text,
            'password': passwordController.text,
            'name': nameController.text,
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
              content: Text('An unexpected issue occurred: \\${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => NavigationUtil.pop(context),
                    child: Text(
                      " Log in here.",
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
              const SizedBox(
                height: 15,
              ),
              Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      autocorrect: false,
                      maxLines: 1,
                      validator: ValidationBuilder().required().build(),
                      decoration: InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    TextFormField(
                      controller: emailController,
                      autocorrect: false,
                      maxLines: 1,
                      validator: ValidationBuilder().email().build(),
                      decoration: InputDecoration(
                        labelText: "E-mail",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    TextFormField(
                      controller: passwordController,
                      autocorrect: false,
                      maxLines: 1,
                      obscureText: passwordHidden,
                      validator: ValidationBuilder()
                          .minLength(8)
                          .maxLength(50)
                          .build(),
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        suffixIcon: IconButton(
                          icon: passwordHidden
                              ? const Icon(Icons.visibility_off_rounded)
                              : const Icon(Icons.visibility_rounded),
                          onPressed: () => setState(
                            () {
                              passwordHidden = !passwordHidden;
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: attemptRegisterAccount,
                  child: const Text("Proceed"),
                ),
              ),
            ],
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
