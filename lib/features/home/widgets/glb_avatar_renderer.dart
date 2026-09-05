import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_motion.dart';
import '../../../shared/models/avatar_scene.dart';
import 'avatar_render_bridge.dart';

class GlbAvatarRenderer extends StatefulWidget {
  final String modelPath;
  final String semanticLabel;
  final AvatarSceneState? sceneState;
  final String? posterPath;
  final VoidCallback? onRenderError;

  const GlbAvatarRenderer({
    required this.modelPath,
    required this.semanticLabel,
    this.sceneState,
    this.posterPath,
    this.onRenderError,
    super.key,
  });

  @override
  State<GlbAvatarRenderer> createState() => _GlbAvatarRendererState();
}

class _GlbAvatarRendererState extends State<GlbAvatarRenderer> {
  WebViewController? _controller;
  bool _modelReady = false;
  bool _reduceMotion = false;
  bool _reportedFailure = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppMotion.reduceMotion(context);
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    _sendSceneState();
  }

  @override
  void didUpdateWidget(covariant GlbAvatarRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modelPath != widget.modelPath) {
      _controller = null;
      _modelReady = false;
      _reportedFailure = false;
      return;
    }
    _sendSceneState();
  }

  void _onWebViewCreated(WebViewController controller) {
    _controller = controller;
  }

  void _onBridgeMessage(String channelName, JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final payload = jsonDecode(message.message);
      if (payload is! Map<String, dynamic>) return;
      if (channelName == 'MMMAvatarReady') {
        setState(() => _modelReady = true);
        _sendSceneState();
      } else if (channelName == 'MMMAvatarError') {
        _reportFailure();
      }
    } on Object catch (error, stackTrace) {
      debugPrint('MMM avatar bridge message failed: $error\n$stackTrace');
    }
  }

  void _reportFailure() {
    if (_reportedFailure) return;
    _reportedFailure = true;
    widget.onRenderError?.call();
  }

  void _sendSceneState() {
    final controller = _controller;
    final state = widget.sceneState;
    if (controller == null || !_modelReady || state == null) return;
    final payload = jsonEncode(state.toJson(reduceMotion: _reduceMotion));
    unawaited(
      controller
          .runJavaScript('window.mmmAvatar.applyLook($payload);')
          .catchError((error, stackTrace) {
            debugPrint('MMM avatar look update failed: $error\n$stackTrace');
            _reportFailure();
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.posterPath != null)
            Image.asset(
              widget.posterPath!,
              fit: BoxFit.contain,
              semanticLabel: widget.semanticLabel,
            ),
          ModelViewer(
            key: ValueKey(widget.modelPath),
            id: 'mmm-avatar',
            src: widget.modelPath,
            alt: widget.semanticLabel,
            backgroundColor: Colors.transparent,
            cameraControls: true,
            disablePan: true,
            disableZoom: true,
            touchAction: TouchAction.panY,
            autoRotate: false,
            autoPlay: false,
            animationCrossfadeDuration: AppMotion.transition.inMilliseconds,
            interactionPrompt: InteractionPrompt.whenFocused,
            loading: Loading.eager,
            reveal: Reveal.auto,
            shadowIntensity: 0.28,
            shadowSoftness: 0.8,
            exposure: 1.05,
            cameraTarget: '0m 0m 2.05m',
            fieldOfView: '30deg',
            debugLogging: false,
            relatedJs: AvatarRenderBridge.script,
            javascriptChannels: {
              JavascriptChannel(
                'MMMAvatarReady',
                onMessageReceived: (message) =>
                    _onBridgeMessage('MMMAvatarReady', message),
              ),
              JavascriptChannel(
                'MMMAvatarError',
                onMessageReceived: (message) =>
                    _onBridgeMessage('MMMAvatarError', message),
              ),
              JavascriptChannel(
                'MMMAvatarMaterialTap',
                onMessageReceived: (message) =>
                    _onBridgeMessage('MMMAvatarMaterialTap', message),
              ),
            },
            onWebViewCreated: _onWebViewCreated,
          ),
        ],
      ),
    );
  }
}
