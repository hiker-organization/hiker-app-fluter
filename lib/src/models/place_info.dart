// Location of a reviewed place (Google Places), as saved by the API.
class PlaceInfo {
  final String placeId;
  final String nome;
  final String? cidade;
  final String? estado;
  final String? siglaEstado;
  final String? pais;
  final String? siglaPais;
  final bool isCidade;
  final String? endereco;

  PlaceInfo({
    required this.placeId,
    required this.nome,
    this.cidade,
    this.estado,
    this.siglaEstado,
    this.pais,
    this.siglaPais,
    this.isCidade = false,
    this.endereco,
  });

  // "Jundiaí, SP, BR". A city doesn't repeat its own name: "SP, BR".
  String get localidade => [
        if (!isCidade) cidade,
        siglaEstado ?? estado,
        siglaPais ?? pais,
      ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  factory PlaceInfo.fromJson(Map<String, dynamic> json) {
    return PlaceInfo(
      placeId: json['place_id'] as String,
      nome: json['nome'] as String,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      siglaEstado: json['sigla_estado'] as String?,
      pais: json['pais'] as String?,
      siglaPais: json['sigla_pais'] as String?,
      isCidade: json['is_cidade'] as bool? ?? false,
      endereco: json['endereco'] as String?,
    );
  }
}

// RF7: place page data.
class PlaceDetails {
  final PlaceInfo info;
  final double? mediaNota;
  final int totalReviews;
  final List<String> tags;

  PlaceDetails({required this.info, required this.mediaNota, required this.totalReviews, required this.tags});

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      info: PlaceInfo.fromJson(json),
      mediaNota: (json['media_nota'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>? ?? []).cast<String>(),
    );
  }
}
