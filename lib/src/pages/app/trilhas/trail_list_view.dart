import 'package:app_hiker/components/profile_summary_header.dart';
import 'package:app_hiker/components/trail_list_tile.dart';
import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/models/user_profile.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/trail_tracker.dart';
import 'package:app_hiker/src/services/trilha_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// RF27: the user's trails, newest first.
class TrailListView extends StatefulWidget {
  final UserProfile? profile;
  final int? postsCount;
  // Opens the tracking screen, for a new trail or for the one in progress.
  final VoidCallback onNewTrail;

  const TrailListView({super.key, required this.profile, this.postsCount, required this.onNewTrail});

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
          ProfileSummaryHeader(profile: widget.profile, postsCount: widget.postsCount),
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
        TrailListTile(trilha: trilha, onTap: () => _openTrilha(trilha)),
        const SizedBox(height: 10),
      ],
    ];
  }
}
