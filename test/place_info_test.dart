import 'package:app_hiker/src/models/place_info.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceInfo _place({bool isCidade = false, String? cidade = 'Jundiaí', String? siglaEstado = 'SP'}) {
  return PlaceInfo(
    placeId: 'x',
    nome: 'Parque da Cidade',
    cidade: cidade,
    estado: 'São Paulo',
    siglaEstado: siglaEstado,
    pais: 'Brasil',
    siglaPais: 'BR',
    isCidade: isCidade,
  );
}

void main() {
  test('shows city, state and country of a place', () {
    expect(_place().localidade, 'Jundiaí, SP, BR');
  });

  test('does not repeat the name of a city', () {
    expect(_place(isCidade: true).localidade, 'SP, BR');
  });

  test('falls back to the state name and skips what is missing', () {
    expect(_place(cidade: null, siglaEstado: null).localidade, 'São Paulo, BR');
  });

  test('reads the API response', () {
    final place = PlaceInfo.fromJson({
      'place_id': 'abc',
      'nome': 'Jundiaí',
      'cidade': 'Jundiaí',
      'estado': 'São Paulo',
      'sigla_estado': 'SP',
      'pais': 'Brasil',
      'sigla_pais': 'BR',
      'is_cidade': true,
      'endereco': null,
    });
    expect(place.localidade, 'SP, BR');
  });
}
