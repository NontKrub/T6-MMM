import 'package:flutter_test/flutter_test.dart';
import 'package:mix_match_mood/core/config/app_config.dart';
import 'package:mix_match_mood/core/services/legal_links_service.dart';

void main() {
  test('both legal documents use the reviewed public HTTPS pages', () {
    expect(
      LegalLinksService.uri(LegalDocument.privacy),
      Uri.parse('${AppConfig.legalPagesBaseUrl}/privacy/'),
    );
    expect(
      LegalLinksService.uri(LegalDocument.terms),
      Uri.parse('${AppConfig.legalPagesBaseUrl}/terms/'),
    );
  });
}
