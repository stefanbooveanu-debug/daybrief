import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_base.dart';

class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText = '',
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['placeId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText:
          json['mainText'] as String? ?? json['description'] as String? ?? '',
      secondaryText: json['secondaryText'] as String? ?? '',
    );
  }
}

/// Google Places autocomplete via the DayBrief proxy (`server.js`).
class PlacesService {
  PlacesService._();

  static Future<List<PlacePrediction>> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 2) return const [];

    try {
      final response = await http.get(
        ApiBase.uri('/api/places/autocomplete', {'input': query}),
        headers: const {'Accept': 'application/json'},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400 || data['success'] != true) {
        return const [];
      }
      final raw = data['predictions'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => PlacePrediction.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.description.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Uri mapsSearchUri(String query) {
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
  }
}
