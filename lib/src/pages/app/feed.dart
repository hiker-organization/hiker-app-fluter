import 'package:app_hiker/components/header.dart';
import 'package:app_hiker/components/review_card.dart';
import 'package:app_hiker/components/trail_card.dart';
import 'package:app_hiker/src/models/review.dart';
import 'package:app_hiker/src/models/trilha.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/review_service.dart';
import 'package:app_hiker/src/services/trilha_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback onNovaAvaliacaoTap;

  const FeedScreen({super.key, required this.onNovaAvaliacaoTap});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _reviewService = ReviewService();
  final _trilhaService = TrilhaService();

  bool _isLoading = true;
  String? _errorMessage;
  // Reviews and shared trails (RF29) mixed, newest first.
  List<Object> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _reviewService.getFeed(),
        // A failure loading trails shouldn't hide the reviews.
        _trilhaService.getFeed().catchError((Object _) => <Trilha>[]),
      ]);
      final items = <Object>[...results[0], ...results[1]]
        ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));
      if (mounted) setState(() => _items = items);
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Não foi possível carregar o feed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime _createdAt(Object item) => item is Review ? item.createdAt : (item as Trilha).createdAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(onNovaAvaliacaoTap: widget.onNovaAvaliacaoTap),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Pallete.errorColor)),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('Nenhuma review por aqui ainda.', style: TextStyle(color: Pallete.whiteColor)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return item is Trilha ? TrailCard(trilha: item) : ReviewCard(review: item as Review);
        },
      ),
    );
  }
}
