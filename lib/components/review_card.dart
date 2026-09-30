import 'package:app_hiker/src/models/review.dart';
import 'package:app_hiker/src/services/review_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  // Disabled inside a profile, where the author is the profile itself.
  final bool autorTappable;
  // Owner actions; the menu is only shown when they are provided.
  final VoidCallback? onToggleVisibility;
  final VoidCallback? onDelete;

  const ReviewCard({
    super.key,
    required this.review,
    this.autorTappable = true,
    this.onToggleVisibility,
    this.onDelete,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final _reviewService = ReviewService();

  late bool _liked = widget.review.liked;
  late bool _disliked = widget.review.disliked;
  late int _qntLikes = widget.review.qntLikes;
  late int _qntDislikes = widget.review.qntDislikes;

  Future<void> _handleLike() async {
    if (_liked) return;

    final previous = (_liked, _disliked, _qntLikes, _qntDislikes);
    setState(() {
      _qntLikes++;
      if (_disliked) _qntDislikes--;
      _liked = true;
      _disliked = false;
    });

    try {
      await _reviewService.likeReview(widget.review.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = previous.$1;
          _disliked = previous.$2;
          _qntLikes = previous.$3;
          _qntDislikes = previous.$4;
        });
      }
    }
  }

  Future<void> _handleDislike() async {
    if (_disliked) return;

    final previous = (_liked, _disliked, _qntLikes, _qntDislikes);
    setState(() {
      _qntDislikes++;
      if (_liked) _qntLikes--;
      _disliked = true;
      _liked = false;
    });

    try {
      await _reviewService.dislikeReview(widget.review.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = previous.$1;
          _disliked = previous.$2;
          _qntLikes = previous.$3;
          _qntDislikes = previous.$4;
        });
      }
    }
  }

  void _openAutorProfile() {
    final nick = widget.review.autor.nomeUsuario;
    context.pushNamed('/user/${nick.replaceFirst('@', '')}');
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final hasFotoAutor = review.autor.fotoUrl != null && review.autor.fotoUrl!.isNotEmpty;
    final hasOwnerActions = widget.onToggleVisibility != null || widget.onDelete != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Pallete.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Pallete.whiteColor.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.autorTappable ? _openAutorProfile : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: hasFotoAutor
                            ? NetworkImage(review.autor.fotoUrl!)
                            : const AssetImage('assets/img/profile.png') as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.autor.nomeExibicao,
                              style: const TextStyle(color: Pallete.whiteColor, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              review.local,
                              style: const TextStyle(color: Pallete.whiteColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Pallete.primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text('${review.nota}', style: const TextStyle(color: Pallete.whiteColor)),
                ],
              ),
              if (hasOwnerActions) _buildOwnerMenu(),
            ],
          ),
          if (review.oculto) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.visibility_off, size: 14, color: Pallete.whiteColor.withAlpha(160)),
                const SizedBox(width: 4),
                Text(
                  'Oculta · só você vê esta avaliação',
                  style: TextStyle(color: Pallete.whiteColor.withAlpha(160), fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(review.descricao, style: const TextStyle(color: Pallete.whiteColor)),
          const SizedBox(height: 8),
          if(review.tags.isNotEmpty) Wrap(
            spacing: 8,
            runSpacing: 4,
            children: review.tags.map((tag) => Chip(
              label: Text(tag, style: const TextStyle(color: Pallete.whiteColor)),
              backgroundColor: Pallete.primaryColor.withAlpha(99),
            )).toList(),
          ),
          if (review.fotos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.fotos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.fotos[index],
                    width: 240,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: _handleLike,
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up,
                      size: 16,
                      color: _liked ? Pallete.primaryColor : Pallete.whiteColor,
                    ),
                    const SizedBox(width: 4),
                    Text('$_qntLikes', style: const TextStyle(color: Pallete.whiteColor)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: _handleDislike,
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_down,
                      size: 16,
                      color: _disliked ? Pallete.primaryColor : Pallete.whiteColor,
                    ),
                    const SizedBox(width: 4),
                    Text('$_qntDislikes', style: const TextStyle(color: Pallete.whiteColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Pallete.whiteColor, size: 20),
      color: Pallete.surfaceColor,
      onSelected: (value) {
        if (value == 'visibility') widget.onToggleVisibility?.call();
        if (value == 'delete') widget.onDelete?.call();
      },
      itemBuilder: (context) => [
        if (widget.onToggleVisibility != null)
          PopupMenuItem(
            value: 'visibility',
            child: Text(widget.review.oculto ? 'Tornar visível' : 'Ocultar avaliação'),
          ),
        if (widget.onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Text('Excluir', style: TextStyle(color: Pallete.errorColor)),
          ),
      ],
    );
  }
}
