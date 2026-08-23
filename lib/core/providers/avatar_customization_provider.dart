import 'package:flutter_riverpod/legacy.dart';
import '../../shared/models/user_profile.dart';

final skinToneIndexProvider = StateProvider<int>((ref) => 1);
final hairColorIndexProvider = StateProvider<int>((ref) => 1);
final bodyShapeProvider = StateProvider<AvatarBodyShape>(
  (ref) => AvatarBodyShape.female,
);
final hairStyleIndexProvider = StateProvider<int>((ref) => 3);
