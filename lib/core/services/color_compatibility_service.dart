import 'dart:math' as math;

import '../../shared/models/clothing_item.dart';
import 'clothing_analysis_service.dart';

class ColorCompatibilityService {
  const ColorCompatibilityService();

  double score(List<ClothingItem> items) {
    final palettes = items.map(_palette).toList();
    final pairs = <double>[];
    for (var i = 0; i < palettes.length; i++) {
      for (var j = i + 1; j < palettes.length; j++) {
        if (palettes[i].isEmpty || palettes[j].isEmpty) {
          pairs.add(50);
          continue;
        }
        var best = 0.0;
        for (final first in palettes[i]) {
          for (final second in palettes[j]) {
            best = math.max(best, compatibility(first, second));
          }
        }
        pairs.add(best);
      }
    }
    if (pairs.isEmpty) return 50;
    return pairs.reduce((a, b) => a + b) / pairs.length;
  }

  double compatibility(String first, String second) {
    final a = _toHsl(first);
    final b = _toHsl(second);
    if (a == null || b == null) return 50;

    final firstNeutral = a.saturation < .12;
    final secondNeutral = b.saturation < .12;
    if (firstNeutral && secondNeutral) {
      return _brightnessContrast(a.lightness, b.lightness, 90);
    }
    if (firstNeutral != secondNeutral) {
      return _brightnessContrast(a.lightness, b.lightness, 84);
    }

    final hueDistance = _hueDistance(a.hue, b.hue);
    var score = switch (hueDistance) {
      <= .08 => 80.0,
      <= .18 => 78.0,
      >= .42 && <= .58 => 72.0,
      >= .30 && <= .70 => 64.0,
      _ => 48.0,
    };
    final saturationDifference = (a.saturation - b.saturation).abs();
    if (saturationDifference <= .25) score += 5;
    if ((a.lightness - b.lightness).abs() < .08) {
      score -= 10;
    } else if ((a.lightness - b.lightness).abs() <= .55) {
      score += 5;
    }
    return score.clamp(0, 100).toDouble();
  }

  List<String> _palette(ClothingItem item) {
    final hexes = item.colorHexes.map(normalizeHexColor).whereType<String>();
    final semantic = _semanticColor(item.color);
    return {...hexes, ?semantic}.take(3).toList();
  }

  String? _semanticColor(String? value) {
    final normalized = value?.trim().toLowerCase();
    return _namedColors[normalized];
  }

  double _brightnessContrast(double first, double second, double base) {
    final difference = (first - second).abs();
    if (difference < .05) return base - 8;
    if (difference > .75) return base - 4;
    return base + 4;
  }

  double _hueDistance(double first, double second) {
    final difference = (first - second).abs();
    return math.min(difference, 1 - difference);
  }

  _Hsl? _toHsl(String value) {
    final hex = normalizeHexColor(value);
    if (hex == null) return null;
    final red = int.parse(hex.substring(1, 3), radix: 16) / 255;
    final green = int.parse(hex.substring(3, 5), radix: 16) / 255;
    final blue = int.parse(hex.substring(5, 7), radix: 16) / 255;
    final max = math.max(red, math.max(green, blue));
    final min = math.min(red, math.min(green, blue));
    final lightness = (max + min) / 2;
    if (max == min) return _Hsl(0, 0, lightness);
    final delta = max - min;
    final saturation = lightness > .5
        ? delta / (2 - max - min)
        : delta / (max + min);
    final hue = max == red
        ? ((green - blue) / delta + (green < blue ? 6 : 0)) / 6
        : max == green
        ? ((blue - red) / delta + 2) / 6
        : ((red - green) / delta + 4) / 6;
    return _Hsl(hue, saturation, lightness);
  }
}

const _namedColors = <String?, String>{
  'black': '#111111',
  'white': '#F5F5F5',
  'gray': '#808080',
  'grey': '#808080',
  'red': '#D32F2F',
  'blue': '#1976D2',
  'navy': '#1B2A49',
  'green': '#388E3C',
  'olive': '#808000',
  'teal': '#00897B',
  'brown': '#795548',
  'beige': '#DFCCAA',
  'cream': '#FFF4D6',
  'yellow': '#FBC02D',
  'orange': '#F57C00',
  'purple': '#7B1FA2',
  'pink': '#E91E63',
  'coral': '#FF7F50',
  'rose': '#E91E63',
  'mint': '#98FF98',
  'sky blue': '#87CEEB',
  'charcoal': '#36454F',
  'silver': '#C0C0C0',
  'tan': '#D2B48C',
};

class _Hsl {
  const _Hsl(this.hue, this.saturation, this.lightness);

  final double hue;
  final double saturation;
  final double lightness;
}
