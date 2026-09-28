import 'dart:async';
import 'dart:io';

import 'package:app_hiker/components/submit_button.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/places_service.dart';
import 'package:app_hiker/src/services/review_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';

class NovaAvaliacaoScreen extends StatefulWidget {
  final VoidCallback onPublished;

  const NovaAvaliacaoScreen({super.key, required this.onPublished});

  @override
  State<NovaAvaliacaoScreen> createState() => _NovaAvaliacaoScreenState();
}

class _NovaAvaliacaoScreenState extends State<NovaAvaliacaoScreen> {
  static const _maxDescricao = 150;
  static const _maxFotos = 5;
  static const _maxFotoBytes = 10 * 1024 * 1024;
  static const _notaLabels = ['Ruim', 'Regular', 'Boa', 'Muito boa', 'Excelente'];

  final _reviewService = ReviewService();
  final _placesService = PlacesService();
  final _imagePicker = ImagePicker();

  final _localController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tagController = TextEditingController();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searchingPlaces = false;
  String? _placesError;

  PlaceSuggestion? _local;
  int _nota = 0;
  final List<String> _tags = [];
  final List<XFile> _fotos = [];
  bool _oculto = false;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _debounce?.cancel();
    _localController.dispose();
    _descricaoController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onLocalChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _placesError = null;
        _searchingPlaces = false;
      });
      return;
    }

    setState(() => _searchingPlaces = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestions = await _placesService.autocomplete(query);
        if (!mounted || _localController.text.trim() != query) return;
        setState(() {
          _suggestions = suggestions;
          _placesError = suggestions.isEmpty ? 'Nenhum local encontrado.' : null;
        });
      } catch (_) {
        if (mounted) setState(() => _placesError = 'Não foi possível buscar locais.');
      } finally {
        if (mounted) setState(() => _searchingPlaces = false);
      }
    });
  }

  void _selectLocal(PlaceSuggestion place) {
    FocusScope.of(context).unfocus();
    setState(() {
      _local = place;
      _suggestions = [];
      _placesError = null;
      _localController.clear();
    });
  }

  void _addTags(String raw) {
    final novas = raw
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty && !_tags.contains(t));
    setState(() {
      _tags.addAll(novas);
      _tagController.clear();
    });
  }

  void _onTagChanged(String value) {
    if (value.contains(',')) _addTags(value);
  }

  Future<void> _pickFotos() async {
    final restantes = _maxFotos - _fotos.length;
    if (restantes <= 0) return;

    final escolhidas = await _imagePicker.pickMultiImage(
      limit: restantes,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (escolhidas.isEmpty) return;

    final validas = <XFile>[];
    final problemas = <String>[];
    for (final foto in escolhidas.take(restantes)) {
      final extensao = foto.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extensao)) {
        problemas.add('${foto.name}: formato não suportado');
      } else if (await foto.length() > _maxFotoBytes) {
        problemas.add('${foto.name}: maior que 10 MB');
      } else {
        validas.add(foto);
      }
    }
    if (escolhidas.length > restantes) {
      problemas.add('Só é possível adicionar $_maxFotos fotos.');
    }

    setState(() {
      _fotos.addAll(validas);
      _errorMessage = problemas.isEmpty ? null : problemas.join('\n');
    });
  }

  String? _validate() {
    if (_local == null) return 'Escolha o local da experiência.';
    if (_nota < 1 || _nota > 5) return 'Dê uma nota de 1 a 5 estrelas.';
    final descricao = _descricaoController.text.trim();
    if (descricao.isEmpty) return 'Conte como foi a sua experiência.';
    if (descricao.length > _maxDescricao) {
      return 'A descrição pode ter no máximo $_maxDescricao caracteres.';
    }
    return null;
  }

  Future<void> handlePublish() async {
    if (_tagController.text.trim().isNotEmpty) _addTags(_tagController.text);

    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _reviewService.createReview(
        localId: _local!.placeId,
        local: _local!.name,
        descricao: _descricaoController.text.trim(),
        nota: _nota,
        oculto: _oculto,
        tags: _tags,
        fotoPaths: _fotos.map((f) => f.path).toList(),
      );
      if (!mounted) return;
      _reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação publicada!')),
      );
      widget.onPublished();
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } on ReviewException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Erro ao conectar com o servidor.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _reset() {
    _descricaoController.clear();
    _tagController.clear();
    _localController.clear();
    setState(() {
      _local = null;
      _nota = 0;
      _tags.clear();
      _fotos.clear();
      _oculto = false;
      _suggestions = [];
    });
  }

  InputDecoration _decoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.all(12),
      prefixIcon: icon == null ? null : Icon(icon, color: Pallete.whiteColor.withAlpha(180), size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Pallete.borderColor, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Pallete.primaryColor, width: 1.5),
      ),
    );
  }

  Widget _section(String title, String hint, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(hint, style: TextStyle(fontSize: 13, color: Pallete.whiteColor.withAlpha(160))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildLocal() {
    if (_local != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Pallete.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Pallete.primaryColor.withAlpha(120)),
        ),
        child: Row(
          children: [
            const Icon(Icons.place, color: Pallete.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_local!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_local!.address != null)
                    Text(
                      _local!.address!,
                      style: TextStyle(fontSize: 12, color: Pallete.whiteColor.withAlpha(160)),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Trocar local',
              icon: const Icon(Icons.close, size: 20),
              onPressed: _isLoading ? null : () => setState(() => _local = null),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _localController,
          onChanged: _onLocalChanged,
          decoration: _decoration('Buscar parque, trilha, pico...', icon: Icons.search).copyWith(
            suffixIcon: _searchingPlaces
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
        ),
        if (_placesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_placesError!, style: TextStyle(color: Pallete.whiteColor.withAlpha(160))),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Pallete.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _suggestions
                  .map((place) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined),
                        title: Text(place.name),
                        subtitle: place.address == null ? null : Text(place.address!),
                        onTap: () => _selectLocal(place),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildNota() {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _isLoading ? null : () => setState(() => _nota = i),
            icon: Icon(
              i <= _nota ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Pallete.primaryColor,
              size: 34,
            ),
          ),
        const SizedBox(width: 8),
        if (_nota > 0)
          Text(_notaLabels[_nota - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _tagController,
          onChanged: _onTagChanged,
          onSubmitted: _addTags,
          textInputAction: TextInputAction.done,
          decoration: _decoration('Ex.: cachoeira, iniciante', icon: Icons.sell_outlined).copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTags(_tagController.text),
            ),
          ),
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Pallete.primaryColor.withAlpha(99),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFotos() {
    const size = 88.0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final foto in _fotos)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(foto.path), width: size, height: size, fit: BoxFit.cover),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: _isLoading ? null : () => setState(() => _fotos.remove(foto)),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Pallete.whiteColor),
                  ),
                ),
              ),
            ],
          ),
        if (_fotos.length < _maxFotos)
          InkWell(
            onTap: _isLoading ? null : _pickFotos,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Pallete.whiteColor.withAlpha(60)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined),
                  const SizedBox(height: 4),
                  Text('${_fotos.length}/$_maxFotos', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nova avaliação', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Compartilhe sua experiência para ajudar outros trilheiros.',
              style: TextStyle(color: Pallete.whiteColor.withAlpha(160)),
            ),
            const SizedBox(height: 24),
            _section('Onde foi?', 'Busque pelo nome do parque, trilha ou pico.', _buildLocal()),
            _section('Sua nota', 'De 1 a 5 estrelas.', _buildNota()),
            _section(
              'Conte como foi',
              'Dificuldade, sinalização, estrutura, paisagem...',
              TextField(
                controller: _descricaoController,
                maxLength: _maxDescricao,
                maxLines: 4,
                minLines: 3,
                decoration: _decoration('Como foi a sua experiência?'),
              ),
            ),
            _section(
              'Tags (opcional)',
              'Palavras-chave que ajudam na busca. Separe por vírgula ou toque em +.',
              _buildTags(),
            ),
            _section(
              'Fotos (opcional)',
              'Até $_maxFotos fotos em JPG ou PNG, com no máximo 10 MB cada.',
              _buildFotos(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _oculto,
              activeTrackColor: Pallete.primaryColor,
              onChanged: _isLoading ? null : (value) => setState(() => _oculto = value),
              title: const Text('Ocultar avaliação', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Avaliações ocultas não aparecem no feed.',
                style: TextStyle(fontSize: 13, color: Pallete.whiteColor.withAlpha(160)),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Pallete.errorColor),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SubmitButton(
              label: 'Publicar',
              isLoading: _isLoading,
              onPressed: handlePublish,
              horizontalPadding: 0,
            ),
          ],
        ),
      ),
    );
  }
}
