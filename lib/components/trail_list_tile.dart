import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:app_hiker/src/utils/trail_format.dart';
import 'package:flutter/material.dart';

// Trail row of the prototype: name and place on the left, date, rating and km on the right.
class TrailListTile extends StatelessWidget {
  final Trilha trilha;
  final VoidCallback onTap;

  const TrailListTile({super.key, required this.trilha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Pallete.surfaceColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trilha.nome, style: const TextStyle(color: Pallete.whiteColor, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(
                      trilha.localidade.isEmpty ? 'Local não identificado' : trilha.localidade,
                      style: const TextStyle(color: Pallete.whiteColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      if (trilha.compartilhada) ...[
                        Icon(Icons.near_me_outlined, size: 14, color: Pallete.whiteColor.withAlpha(200)),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        formatTrailDate(trilha.iniciadaEm),
                        style: const TextStyle(color: Pallete.whiteColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= trilha.nota ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 12,
                          color: Pallete.primaryColor,
                        ),
                    ],
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatKm(trilha.distanciaM),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' KM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    style: const TextStyle(color: Pallete.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
