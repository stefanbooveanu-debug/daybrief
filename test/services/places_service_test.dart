import 'package:flutter_test/flutter_test.dart';

import 'package:day_brief/services/places_service.dart';

void main() {
  test('mapsSearchUri encodes query for Google Maps', () {
    final uri = PlacesService.mapsSearchUri('Central Park, NYC');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['query'], 'Central Park, NYC');
  });

  test('PlacePrediction.fromJson maps fields', () {
    final p = PlacePrediction.fromJson({
      'placeId': 'abc',
      'description': 'Cafe, Street 1',
      'mainText': 'Cafe',
      'secondaryText': 'Street 1',
    });
    expect(p.placeId, 'abc');
    expect(p.mainText, 'Cafe');
    expect(p.secondaryText, 'Street 1');
  });
}
