import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const feedback = Duration(milliseconds: 140);
  static const selection = Duration(milliseconds: 200);
  static const transition = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration duration(BuildContext context, Duration value) =>
      reduceMotion(context) ? Duration.zero : value;
}
