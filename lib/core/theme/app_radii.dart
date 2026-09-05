import 'package:flutter/widgets.dart';

abstract final class AppRadii {
  static const compact = Radius.circular(12);
  static const control = Radius.circular(16);
  static const card = Radius.circular(20);
  static const emphasizedCard = Radius.circular(24);
  static const sheet = Radius.circular(28);
  static const hero = Radius.circular(32);

  static const compactBorder = BorderRadius.all(compact);
  static const controlBorder = BorderRadius.all(control);
  static const cardBorder = BorderRadius.all(card);
  static const emphasizedCardBorder = BorderRadius.all(emphasizedCard);
  static const heroBorder = BorderRadius.all(hero);
  static const sheetBorder = BorderRadius.vertical(top: sheet);
}
