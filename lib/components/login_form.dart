import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;
  const LoginForm({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(constraints: const BoxConstraints(maxWidth: 312),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.all(12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Pallete.borderColor, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Pallete.primaryColor, width: 1.5),
        ),
        hintText: hintText,
      ),
      obscureText: obscureText,
    ));
  }
}