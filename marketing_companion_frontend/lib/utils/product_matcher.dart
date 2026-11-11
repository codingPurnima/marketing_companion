
String normalizeVoiceText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? extractProductName(
  String command,
  List<String> prefixes,
) {
  for (final prefix in prefixes) {
    if (command.startsWith('$prefix ')) {
      return command.substring(prefix.length).trim();
    }
  }

  return null;
}

List<Map<String, dynamic>> findMatchingProducts(
  String query, {
  required List<dynamic> source,
}) {
  final normalizedQuery = normalizeVoiceText(query);
  final queryWords = normalizedQuery.split(' ').toSet();
  final matches = <Map<String, dynamic>>[];

  for (final item in source) {
    final product = Map<String, dynamic>.from(item as Map);
    final title = normalizeVoiceText(
      product['title']?.toString() ?? '',
    );

    if (title.isEmpty) continue;

    final titleWords = title.split(' ').toSet();

    double score = 0;

    if (title == normalizedQuery) {
      score = 2;
    } else if (title.contains(normalizedQuery) ||
        normalizedQuery.contains(title)) {
      score = 1.5;
    } else {
      final commonWords = queryWords.intersection(titleWords);
      score = commonWords.length / queryWords.length;
    }

    if (score >= 0.6) {
      product['_matchScore'] = score;
      matches.add(product);
    }
  }

  matches.sort(
    (a, b) => (b['_matchScore'] as double)
        .compareTo(a['_matchScore'] as double),
  );

  return matches;
}