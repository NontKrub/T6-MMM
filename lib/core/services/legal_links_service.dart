import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

enum LegalDocument { terms, privacy }

abstract final class LegalLinksService {
  static Uri? uri(LegalDocument document) {
    final raw = switch (document) {
      LegalDocument.terms => AppConfig.termsOfServiceUrl,
      LegalDocument.privacy => AppConfig.privacyPolicyUrl,
    };
    final parsed = Uri.tryParse(raw.trim());
    if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
      return null;
    }
    return parsed;
  }

  static Future<bool> open(LegalDocument document) async {
    final target = uri(document);
    return target != null &&
        await launchUrl(target, mode: LaunchMode.externalApplication);
  }
}
