import 'package:app_hiker/components/profile_summary_header.dart';
import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/models/user_profile.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/trail_tracker.dart';
import 'package:app_hiker/src/services/trilha_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:app_hiker/src/utils/trail_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// RF27: the user's trails, newest first.
class TrailListView extends StatefulWidget {
  final UserProfile? profile;
  // Opens the tracking screen, for a new trail or for the one in progress.
  final VoidCallback onNewTrail;

  const TrailListView({super.key, required this.profile, required this.onNewTrail});

  @override
  State<TrailListView> createState() => _TrailListViewState();
}

class _TrailListViewState extends State<TrailListView> {
  final _trilhaService = TrilhaService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Trilha> _trilhas = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final trilhas = await _trilhaService.getMine();
      if (mounted) setState(() => _trilhas = trilhas);
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Não foi possível carregar suas trilhas.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openTrilha(Trilha trilha) async {
    await context.pushNamed('/trilha/${trilha.id}');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final inProgress = TrailTracker.instance.hasTrail;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ProfileSummaryHeader(profile: widget.profile),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: widget.onNewTrail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(inProgress ? Icons.directions_walk : Icons.add, color: Pallete.whiteColor),
              label: Text(
                inProgress ? 'Continuar trilha em andamento' : 'Nova Trilha',
                style: const TextStyle(color: Pallete.whiteColor, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._buildList(),
        ],
      ),
    );
  }

  List<Widget> _buildList() {
    if (_isLoading) {
      return const [Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))];
    }
    if (_errorMessage != null) {
      return [
        Center(child: Text(_errorMessage!, style: const TextStyle(color: Pallete.errorColor))),
        TextButton(
          onPressed: _load,
          child: const Text('Tentar novamente', style: TextStyle(color: Pallete.primaryColor)),
        ),
      ];
    }
    if (_trilhas.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'Você ainda não registrou nenhuma trilha.\nToque em "Nova Trilha" para começar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Pallete.whiteColor.withAlpha(160)),
          ),
        ),
      ];
    }
    return [
      for (final trilha in _trilhas) ...[
        _TrailListTile(trilha: trilha, onTap: () => _openTrilha(trilha)),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _TrailListTile extends StatelessWidget {
  final Trilha trilha;
  final VoidCallback onTap;

  const _TrailListTile({required this.trilha, required this.onTap});

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
