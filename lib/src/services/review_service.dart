import 'dart:convert';

import 'package:app_hiker/src/models/review.dart';
import 'package:app_hiker/src/services/api_client.dart';

class ReviewService {
  final ApiClient _apiClient;

  ReviewService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Review>> getFeed({int? cursor}) async {
    final query = cursor != null ? '?cursor=$cursor' : '';
    final response = await _apiClient.get('/review$query');

    if (response.statusCode == 404) return [];

    if (response.statusCode != 200) {
      throw Exception('Não foi possível carregar o feed');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> likeReview(int id) async {
    final response = await _apiClient.post('/review/$id/like');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Não foi possível curtir a review');
    }
  }

  Future<void> dislikeReview(int id) async {
    final response = await _apiClient.post('/review/$id/dislike');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Não foi possível descurtir a review');
    }
  }
}
