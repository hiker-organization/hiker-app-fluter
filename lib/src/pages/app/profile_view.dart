import 'package:app_hiker/components/review_card.dart';
import 'package:app_hiker/src/models/review.dart';
import 'package:app_hiker/src/models/user_profile.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/review_service.dart';
import 'package:app_hiker/src/services/user_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// Shared body of the own profile (RF16) and of another user's profile (RF14).
// Hidden reviews are only listed on the own profile: /user/me returns them, while
// /user/:nick filters them out on the API, including from the review count.
class ProfileView extends StatefulWidget {
  // null opens the logged user's profile.
  final String? nick;

  const ProfileView({super.key, this.nick});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _userService = UserService();
  final _reviewService = ReviewService();

  bool _isLoading = true;
  String? _errorMessage;
  UserProfile? _profile;
  List<Review> _reviews = [];

  bool get _isOwn => widget.nick == null || widget.nick == UserService.myNick;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = _isOwn
          ? await _userService.getMe()
          : await _userService.getUserProfile(widget.nick!);
      if (mounted) {
        setState(() {
          _profile = profile;
          _reviews = profile.reviews;
        });
      }
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } on UserNotFoundException {
      if (mounted) setState(() => _errorMessage = 'Usuário não encontrado.');
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Não foi possível carregar o perfil.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility(Review review) async {
    final oculto = !review.oculto;
    try {
      await _reviewService.setVisibility(review.id, oculto: oculto);
      if (!mounted) return;
      setState(() {
        _reviews = _reviews.map((r) => r.id == review.id ? _withOculto(r, oculto) : r).toList();
      });
      _showMessage(oculto ? 'Avaliação oculta. Só você pode vê-la.' : 'Avaliação visível para todos.');
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (e) {
      _showMessage(e is ReviewException ? e.message : 'Não foi possível alterar a visibilidade.');
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Pallete.surfaceColor,
        title: const Text('Excluir avaliação'),
        content: const Text('Tem certeza que deseja excluir esta avaliação?'),
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

    try {
      await _reviewService.deleteReview(review.id);
      if (!mounted) return;
      setState(() => _reviews = _reviews.where((r) => r.id != review.id).toList());
      _showMessage('Avaliação excluída.');
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } catch (e) {
      _showMessage(e is ReviewException ? e.message : 'Não foi possível excluir a avaliação.');
    }
  }

  Review _withOculto(Review r, bool oculto) => Review(
        id: r.id,
        descricao: r.descricao,
        local: r.local,
        qntLikes: r.qntLikes,
        qntDislikes: r.qntDislikes,
        nota: r.nota,
        createdAt: r.createdAt,
        autor: r.autor,
        fotos: r.fotos,
        tags: r.tags,
        liked: r.liked,
        disliked: r.disliked,
        oculto: oculto,
      );

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Pallete.errorColor)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadProfile,
              child: const Text('Tentar novamente', style: TextStyle(color: Pallete.primaryColor)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(_profile!),
          const SizedBox(height: 24),
          const Text(
            'Publicações',
            style: TextStyle(color: Pallete.whiteColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                _isOwn ? 'Você ainda não publicou nenhuma avaliação.' : 'Nenhuma publicação por aqui ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Pallete.whiteColor.withAlpha(160)),
              ),
            ),
          for (final review in _reviews) ...[
            ReviewCard(
              key: ValueKey(review.id),
              review: review,
              autorTappable: false,
              onToggleVisibility: _isOwn ? () => _toggleVisibility(review) : null,
              onDelete: _isOwn ? () => _deleteReview(review) : null,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    final hasFoto = profile.fotoUrl != null && profile.fotoUrl!.isNotEmpty;

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Pallete.surfaceColor,
          backgroundImage: hasFoto
              ? NetworkImage(profile.fotoUrl!)
              : const AssetImage('assets/img/profile.png') as ImageProvider,
        ),
        const SizedBox(height: 12),
        Text(
          profile.nomeExibicao,
          style: const TextStyle(color: Pallete.whiteColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(profile.nomeUsuario, style: TextStyle(color: Pallete.whiteColor.withAlpha(160))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStat('${_reviews.length}', 'Publicações'),
            const SizedBox(width: 32),
            _buildStat(profile.reputacao.toStringAsFixed(1), 'Reputação'),
          ],
        ),
        if (_isOwn) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed('/edit-profile'),
            icon: const Icon(Icons.edit, size: 16, color: Pallete.primaryColor),
            label: const Text('Editar perfil', style: TextStyle(color: Pallete.primaryColor)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Pallete.primaryColor)),
          ),
        ],
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Pallete.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Pallete.whiteColor.withAlpha(160), fontSize: 12)),
      ],
    );
  }
}
