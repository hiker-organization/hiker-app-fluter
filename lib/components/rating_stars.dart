import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';

// Rating as one filled star per point, followed by the number, so it is clear what the
// number means.
class RatingStars extends StatelessWidget {
  final int nota;
  final double size;

  const RatingStars({super.key, required this.nota, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nota $nota de 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < nota; i++) Icon(Icons.star_rounded, color: Pallete.primaryColor, size: size),
          const SizedBox(width: 4),
          Text('$nota', style: TextStyle(color: Pallete.whiteColor, fontSize: size * 0.85)),
        ],
      ),
    );
  }
}
