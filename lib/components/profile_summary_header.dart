import 'package:app_hiker/components/user_avatar.dart';
import 'package:app_hiker/src/models/user_profile.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';

// Header of the trail screens in the prototype: photo with posts and reputation on the sides.
class ProfileSummaryHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onBack;

  const ProfileSummaryHeader({super.key, required this.profile, this.onBack});

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Pallete.whiteColor),
                    onPressed: onBack,
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(child: _stat(profile == null ? '-' : '${profile.reviews.length}', 'Posts')),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Pallete.primaryColor, shape: BoxShape.circle),
                child: UserAvatar(photoUrl: profile?.fotoUrl, radius: 40),
              ),
              Expanded(
                child: _stat(profile == null ? '-' : profile.reputacao.toStringAsFixed(1), 'Reputação'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile?.nomeUsuario ?? '',
            style: const TextStyle(color: Pallete.whiteColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Pallete.whiteColor, fontSize: 18)),
        Text(label, style: TextStyle(color: Pallete.whiteColor.withAlpha(180), fontSize: 12)),
      ],
    );
  }
}
