import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SocialButton extends StatelessWidget {
  final String iconName;
  final String label;
  final double horizontalPadding;
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.iconName,
    required this.label,
    this.horizontalPadding = 80,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        'assets/svg/$iconName.svg',
        width: 24,
        height: 24,
        colorFilter: const ColorFilter.mode(
          Pallete.whiteColor,
          BlendMode.srcIn,
        ),
      ),
      label: Text(
        label,
        style: const TextStyle(color: Pallete.whiteColor)
      ),
      style: TextButton.styleFrom(
        backgroundColor: Pallete.backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Pallete.borderColor, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
      )
    );
  }
}
