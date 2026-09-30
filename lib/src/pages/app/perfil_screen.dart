import 'package:app_hiker/src/pages/app/profile_view.dart';
import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  final VoidCallback? onProfileEdited;

  const PerfilScreen({super.key, this.onProfileEdited});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: ProfileView(onProfileEdited: onProfileEdited));
  }
}
