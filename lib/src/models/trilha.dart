import 'package:app_hiker/src/models/review.dart';
import 'package:latlong2/latlong.dart';

// Route segments, one per tracking session between pauses.
typedef TrailRoute = List<List<LatLng>>;

TrailRoute parseRoute(dynamic json) {
  if (json is! List) return [];
  return json
      .map((segment) => (segment as List)
          .map((point) => LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble()))
          .toList())
      .toList();
}

List<List<List<double>>> routeToJson(TrailRoute route) =>
    route.map((segment) => segment.map((p) => [p.latitude, p.longitude]).toList()).toList();

class Trilha {
  final int id;
  final String nome;
  final String? cidade;
  final String? estado;
  final double distanciaM;
  final int passos;
  final int duracaoS;
  final int nota;
  final bool compartilhada;
  final DateTime iniciadaEm;
  final DateTime createdAt;
  // Only in the detail and in the feed; the list of own trails doesn't send them.
  final String? descricao;
  final TrailRoute rota;
  final ReviewAutor? autor;
  final List<String> fotos;
  final List<String> tags;
  final bool dono;

  Trilha({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.estado,
    required this.distanciaM,
    required this.passos,
    required this.duracaoS,
    required this.nota,
    required this.compartilhada,
    required this.iniciadaEm,
    required this.createdAt,
    this.descricao,
    this.rota = const [],
    this.autor,
    this.fotos = const [],
    this.tags = const [],
    this.dono = false,
  });

  // "Jundiaí, São Paulo", skipping what is missing.
  String get localidade => [cidade, estado].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  factory Trilha.fromJson(Map<String, dynamic> json) {
    final autor = json['autor'] as Map<String, dynamic>?;
    return Trilha(
      id: json['id'] as int,
      nome: json['nome'] as String,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      distanciaM: (json['distancia_m'] as num).toDouble(),
      passos: json['passos'] as int,
      duracaoS: json['duracao_s'] as int,
      nota: json['nota'] as int,
      compartilhada: json['compartilhada'] as bool? ?? false,
      iniciadaEm: DateTime.parse(json['iniciada_em'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      descricao: json['descricao'] as String?,
      rota: parseRoute(json['rota']),
      autor: autor != null ? ReviewAutor.fromJson(autor) : null,
      fotos: (json['fotos'] as List<dynamic>? ?? []).map((foto) => foto['url'] as String).toList(),
      tags: (json['tags'] as List<dynamic>? ?? []).map((tag) => tag['tag']['descritivo'] as String).toList(),
      dono: json['dono'] as bool? ?? false,
    );
  }
}
