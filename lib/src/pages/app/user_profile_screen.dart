import 'package:app_hiker/src/pages/app/profile_view.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// Profile opened from a review author. ProfileView falls back to the own profile
// when the nick is the logged user's.
class UserProfileScreen extends StatelessWidget {
  final String nick;

  const UserProfileScreen({super.key, required this.nick});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Pallete.whiteColor),
          onPressed: () => context.pop(),
        ),
        title: Text(nick, style: const TextStyle(color: Pallete.whiteColor, fontSize: 16)),
      ),
      body: ProfileView(nick: nick),
    );
  }
}
