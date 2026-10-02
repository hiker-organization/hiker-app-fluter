import 'package:app_hiker/components/trail_map.dart';
import 'package:app_hiker/components/user_avatar.dart';
import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:app_hiker/src/utils/trail_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// Shared trail in the feed (RF29).
class TrailCard extends StatelessWidget {
  final Trilha trilha;

  const TrailCard({super.key, required this.trilha});

  @override
  Widget build(BuildContext context) {
    final autor = trilha.autor;

    return Material(
      color: Pallete.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.pushNamed('/trilha/${trilha.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Pallete.whiteColor.withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (autor != null)
                InkWell(
                  onTap: () => context.pushNamed('/user/${autor.nomeUsuario.replaceFirst('@', '')}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      UserAvatar(photoUrl: autor.fotoUrl, radius: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              autor.nomeExibicao,
                              style: const TextStyle(color: Pallete.whiteColor, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'fez uma trilha · ${formatTrailDate(trilha.iniciadaEm)}',
                              style: TextStyle(color: Pallete.whiteColor.withAlpha(160), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trilha.nome,
                          style: const TextStyle(color: Pallete.whiteColor, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (trilha.localidade.isNotEmpty)
                          Text(
                            trilha.localidade,
                            style: TextStyle(color: Pallete.whiteColor.withAlpha(180), fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.star, color: Pallete.primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text('${trilha.nota}', style: const TextStyle(color: Pallete.whiteColor)),
                ],
              ),
              const SizedBox(height: 10),
              IgnorePointer(child: TrailMap(route: trilha.rota, height: 150, interactive: false)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _stat('${formatKm(trilha.distanciaM)} km', 'Distância'),
                  _stat('${trilha.passos}', 'Passos'),
                  _stat(formatDuration(Duration(seconds: trilha.duracaoS)), 'Tempo'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Pallete.primaryColor, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Pallete.whiteColor.withAlpha(160), fontSize: 12)),
        ],
      ),
    );
  }
}
