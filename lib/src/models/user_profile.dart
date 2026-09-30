import 'package:app_hiker/src/models/review.dart';

class UserProfile {
  final String nomeExibicao;
  final String nomeUsuario;
  final String? fotoUrl;
  final num reputacao;
  final List<Review> reviews;

  UserProfile({
    required this.nomeExibicao,
    required this.nomeUsuario,
    required this.fotoUrl,
    required this.reputacao,
    required this.reviews,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final autor = ReviewAutor.fromJson(json);
    // The API doesn't order profile reviews, newest first here.
    final reviews = (json['reviews'] as List<dynamic>)
        .map((item) => Review.fromJson(item as Map<String, dynamic>, autor: autor))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return UserProfile(
      nomeExibicao: autor.nomeExibicao,
      nomeUsuario: autor.nomeUsuario,
      fotoUrl: autor.fotoUrl,
      reputacao: autor.reputacao,
      reviews: reviews,
    );
  }
}
