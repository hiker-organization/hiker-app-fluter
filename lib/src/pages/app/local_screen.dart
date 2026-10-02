import 'package:app_hiker/components/review_card.dart';
import 'package:app_hiker/src/models/place_info.dart';
import 'package:app_hiker/src/models/review.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/local_service.dart';
import 'package:app_hiker/src/services/review_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// RF7: place page with its average rating, labels and the reviews in chronological order.
class LocalScreen extends StatefulWidget {
  final String placeId;

  const LocalScreen({super.key, required this.placeId});

  @override
  State<LocalScreen> createState() => _LocalScreenState();
}

class _LocalScreenState extends State<LocalScreen> {
  final _localService = LocalService();
  final _reviewService = ReviewService();

  PlaceDetails? _details;
  List<Review> _reviews = [];
  bool _isLoading = true;
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
      final detailsFuture = _localService.getDetails(widget.placeId);
      final reviewsFuture = _reviewService.getLocalReviews(widget.placeId);
      await Future.wait([detailsFuture, reviewsFuture]);
      final details = await detailsFuture;
      final reviews = await reviewsFuture;
      if (mounted) {
        setState(() {
          _details = details;
          _reviews = reviews;
        });
      }
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } on LocalException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Não foi possível carregar o local.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pallete.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Pallete.whiteColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Local', style: TextStyle(color: Pallete.whiteColor, fontSize: 18)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _details == null) return const Center(child: CircularProgressIndicator());

    if (_details == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage ?? 'Local não encontrado.', style: const TextStyle(color: Pallete.errorColor)),
            TextButton(
              onPressed: _load,
              child: const Text('Tentar novamente', style: TextStyle(color: Pallete.primaryColor)),
            ),
          ],
        ),
      );
    }

    final details = _details!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(details),
          const SizedBox(height: 24),
          const Text('Avaliações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Ninguém avaliou este local ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Pallete.whiteColor.withAlpha(160)),
              ),
            ),
          for (final review in _reviews) ...[
            ReviewCard(key: ValueKey(review.id), review: review, localTappable: false),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(PlaceDetails details) {
    final info = details.info;
    final media = details.mediaNota;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.nome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        if (info.localidade.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(info.localidade, style: TextStyle(color: Pallete.whiteColor.withAlpha(180))),
        ],
        if (info.endereco != null && !info.isCidade) ...[
          const SizedBox(height: 4),
          Text(info.endereco!, style: TextStyle(color: Pallete.whiteColor.withAlpha(140), fontSize: 12)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _stat(media == null ? '-' : media.toStringAsFixed(1), 'Nota média', icon: Icons.star_rounded),
            const SizedBox(width: 12),
            _stat('${details.totalReviews}', details.totalReviews == 1 ? 'Avaliação' : 'Avaliações'),
          ],
        ),
        if (details.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: details.tags
                .map((tag) => Chip(label: Text(tag), backgroundColor: Pallete.primaryColor.withAlpha(99)))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _stat(String value, String label, {IconData? icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Pallete.surfaceColor, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Pallete.primaryColor, size: 20),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: const TextStyle(color: Pallete.primaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(label, style: TextStyle(color: Pallete.whiteColor.withAlpha(160), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
