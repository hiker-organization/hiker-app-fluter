import 'package:app_hiker/components/trail_map.dart';
import 'package:app_hiker/components/user_avatar.dart';
import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/trilha_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:app_hiker/src/utils/trail_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// RF28: trail details. The owner can also share it (RF29) or delete it (RF30).
class TrilhaDetailScreen extends StatefulWidget {
  final int id;

  const TrilhaDetailScreen({super.key, required this.id});

  @override
  State<TrilhaDetailScreen> createState() => _TrilhaDetailScreenState();
}

class _TrilhaDetailScreenState extends State<TrilhaDetailScreen> {
  final _trilhaService = TrilhaService();

  Trilha? _trilha;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

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
      final trilha = await _trilhaService.getById(widget.id);
      if (mounted) setState(() => _trilha = trilha);
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } on TrilhaException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Não foi possível carregar a trilha.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleShare(bool compartilhada) async {
    setState(() => _isUpdating = true);
    try {
      await _trilhaService.setShared(widget.id, compartilhada: compartilhada);
      await _load();
      _showMessage(compartilhada ? 'Trilha compartilhada no feed.' : 'Trilha removida do feed.');
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (e) {
      _showMessage(e is TrilhaException ? e.message : 'Não foi possível alterar o compartilhamento.');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // RN30.1: asks for confirmation before deleting.
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.surfaceColor,
        title: const Text('Excluir trilha'),
        content: const Text('Tem certeza que deseja excluir esta trilha?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Pallete.whiteColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Pallete.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isUpdating = true);
    try {
      await _trilhaService.delete(widget.id);
      if (!mounted) return;
      _showMessage('Trilha excluída.');
      context.pop();
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (e) {
      _showMessage(e is TrilhaException ? e.message : 'Não foi possível excluir a trilha.');
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final trilha = _trilha;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Pallete.whiteColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trilha', style: TextStyle(color: Pallete.whiteColor, fontSize: 18)),
        actions: [
          if (trilha != null && trilha.dono)
            IconButton(
              tooltip: 'Excluir trilha',
              icon: const Icon(Icons.delete_outline, color: Pallete.errorColor),
              onPressed: _isUpdating ? null : _delete,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _trilha == null) return const Center(child: CircularProgressIndicator());

    if (_trilha == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage ?? 'Trilha não encontrada.', style: const TextStyle(color: Pallete.errorColor)),
            TextButton(
              onPressed: _load,
              child: const Text('Tentar novamente', style: TextStyle(color: Pallete.primaryColor)),
            ),
          ],
        ),
      );
    }

    final trilha = _trilha!;
    final autor = trilha.autor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!trilha.dono && autor != null) ...[
          InkWell(
            onTap: () => context.pushNamed('/user/${autor.nomeUsuario.replaceFirst('@', '')}'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                UserAvatar(photoUrl: autor.fotoUrl, radius: 18),
                const SizedBox(width: 10),
                Text(autor.nomeExibicao, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trilha.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (trilha.localidade.isNotEmpty)
                    Text(trilha.localidade, style: TextStyle(color: Pallete.whiteColor.withAlpha(180))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatTrailDate(trilha.iniciadaEm), style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= trilha.nota ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 18,
                        color: Pallete.primaryColor,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _stat('${formatKm(trilha.distanciaM)} km', 'Distância'),
            _stat('${trilha.passos}', 'Passos'),
            _stat(formatDuration(Duration(seconds: trilha.duracaoS)), 'Tempo'),
          ],
        ),
        const SizedBox(height: 16),
        TrailMap(route: trilha.rota, height: 260),
        if (trilha.descricao != null && trilha.descricao!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(trilha.descricao!, style: const TextStyle(fontSize: 15)),
        ],
        if (trilha.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: trilha.tags
                .map((tag) => Chip(label: Text(tag), backgroundColor: Pallete.primaryColor.withAlpha(99)))
                .toList(),
          ),
        ],
        if (trilha.fotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trilha.fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(trilha.fotos[index], width: 220, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
        if (trilha.dono) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: trilha.compartilhada,
            activeTrackColor: Pallete.primaryColor,
            onChanged: _isUpdating ? null : _toggleShare,
            title: const Text('Compartilhar no feed', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              trilha.compartilhada ? 'Visível para outros trilheiros.' : 'Só você vê esta trilha.',
              style: TextStyle(fontSize: 13, color: Pallete.whiteColor.withAlpha(160)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Pallete.surfaceColor, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(color: Pallete.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(color: Pallete.whiteColor.withAlpha(160), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
