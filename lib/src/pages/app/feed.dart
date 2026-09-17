import 'package:app_hiker/components/header.dart';
import 'package:app_hiker/components/review_card.dart';
import 'package:app_hiker/src/models/review.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/review_service.dart';
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

  bool _isLoading = true;
  String? _errorMessage;
  List<Review> _reviews = [];

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
      final reviews = await _reviewService.getFeed();
      if (mounted) setState(() => _reviews = reviews);
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Não foi possível carregar o feed.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

    if (_reviews.isEmpty) {
      return const Center(
        child: Text('Nenhuma review por aqui ainda.', style: TextStyle(color: Pallete.whiteColor)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => ReviewCard(review: _reviews[index]),
      ),
    );
  }
}
