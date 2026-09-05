import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/theme/app_motion.dart';

class GlbAvatarRenderer extends StatelessWidget {
  final String modelPath;
  final String semanticLabel;
  final String? materialVariant;

  const GlbAvatarRenderer({
    required this.modelPath,
    required this.semanticLabel,
    this.materialVariant,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ModelViewer(
        key: ValueKey('$modelPath:$materialVariant:$reduceMotion'),
        src: modelPath,
        alt: semanticLabel,
        backgroundColor: Colors.transparent,
        cameraControls: true,
        disablePan: true,
        disableZoom: true,
        touchAction: TouchAction.panY,
        // Orbit remains user-controlled; avoid turning the avatar into a
        // continuously spinning showroom model.
        autoRotate: false,
        autoPlay: !reduceMotion,
        animationCrossfadeDuration: AppMotion.transition.inMilliseconds,
        interactionPrompt: InteractionPrompt.whenFocused,
        variantName: materialVariant,
        loading: Loading.eager,
        debugLogging: false,
      ),
    );
  }
}
