import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double horizontalPadding;
  final double verticalPadding;

  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.horizontalPadding = 100,
    this.isLoading = false,
    this.verticalPadding = 15,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Pallete.primaryColor,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: isLoading ? 0 : 1,
            child: Text(label, style: const TextStyle(fontSize: 18, color: Pallete.textDarkColor)),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Pallete.whiteColor,
              ),
            ),
        ],
      ),
    );
  }
}
