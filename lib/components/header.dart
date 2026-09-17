import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class Header extends StatelessWidget {
  final VoidCallback onNovaAvaliacaoTap;

  const Header({super.key, required this.onNovaAvaliacaoTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Pallete.whiteColor),
              onPressed: onNovaAvaliacaoTap,
            ),
            Image.asset('assets/img/logo.png', height: 32),
            IconButton(
              icon: const Icon(Icons.settings, color: Pallete.whiteColor),
              onPressed: () => context.pushNamed('/edit-profile'),
            ),
          ],
        ),
      ),
    );
  }
}
