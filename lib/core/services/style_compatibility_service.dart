import '../../shared/models/clothing_item.dart';

class StyleCompatibilityService {
  const StyleCompatibilityService();

  double score(List<ClothingItem> items, {String? desiredStyle}) {
    if (items.length < 2) return 50;
    final pairScores = <double>[];
    for (var i = 0; i < items.length; i++) {
      for (var j = i + 1; j < items.length; j++) {
        pairScores.add(_pairScore(_styles(items[i]), _styles(items[j])));
      }
    }
    var score = pairScores.reduce((a, b) => a + b) / pairScores.length;
    final desired = _canonical(desiredStyle);
    if (desired != null) {
      final desiredScores = items
          .map((item) => _styles(item))
          .map((styles) => styles.isEmpty ? 50 : _bestDesired(styles, desired))
          .toList();
      final desiredScore =
          desiredScores.reduce((a, b) => a + b) / desiredScores.length;
      score = (score * .65) + (desiredScore * .35);
    }
    return score.clamp(0, 100).toDouble();
  }

  bool isCompatible(String first, String second) =>
      _compatibility(_canonical(first), _canonical(second)) >= .55;

  double _pairScore(Set<String> first, Set<String> second) {
    if (first.isEmpty || second.isEmpty) return 55;
    var best = 0.0;
    for (final a in first) {
      for (final b in second) {
        best = best < _compatibility(a, b) ? _compatibility(a, b) : best;
      }
    }
    return best * 100;
  }

  double _bestDesired(Set<String> styles, String desired) {
    var best = 0.0;
    for (final style in styles) {
      final value = _compatibility(style, desired);
      if (value > best) best = value;
    }
    return best * 100;
  }

  Set<String> _styles(ClothingItem item) => {
    ...item.styles
        .where((style) => style != ClothingStyle.unknown)
        .map((style) => style.name),
    ...item.tags.map(_canonical).whereType<String>(),
  };

  String? _canonical(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll('-', '');
    return switch (normalized) {
      'casual' => 'casual',
      'streetwear' => 'streetwear',
      'formal' => 'formal',
      'business' || 'work' => 'business',
      'sport' || 'sportswear' || 'athletic' => 'sport',
      'minimal' => 'minimal',
      'vintage' => 'vintage',
      'preppy' => 'preppy',
      'smartcasual' => 'smartCasual',
      _ => null,
    };
  }

  double _compatibility(String? first, String? second) {
    if (first == null || second == null) return .55;
    if (first == second) return .92;
    final key = [first, second]..sort();
    return _matrix[key.join('|')] ?? .45;
  }
}

const _matrix = <String, double>{
  'casual|sport': .78,
  'casual|streetwear': .9,
  'business|formal': .82,
  'business|smartCasual': .86,
  'formal|smartCasual': .68,
  'minimal|smartCasual': .78,
  'preppy|smartCasual': .8,
  'casual|minimal': .76,
  'casual|vintage': .72,
  'sport|streetwear': .76,
  'minimal|streetwear': .62,
  'preppy|casual': .65,
  'formal|streetwear': .28,
  'formal|sport': .25,
  'business|streetwear': .35,
  'business|sport': .3,
};
