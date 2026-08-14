import 'package:creovo_invoice/app/localization/app_localization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App localization', () {
    test('supports English, Hindi, and Gujarati with English fallback', () {
      expect(AppLanguage.values.map((value) => value.code), ['en', 'hi', 'gu']);
      expect(AppLanguage.fromCode(null), AppLanguage.english);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.english);
      expect(AppLanguage.fromCode('hi'), AppLanguage.hindi);
      expect(AppLanguage.fromCode('gu'), AppLanguage.gujarati);
    });

    test('translates representative copy from every main workflow', () {
      const phrases = [
        'Home',
        'Invoices',
        'Customers',
        'Products & services',
        'Business profile',
        'Invoice defaults',
        'Product settings',
        'Payment receipt',
        'Reports',
        'Backup & restore',
        'Choose language',
      ];
      for (final language in [AppLanguage.hindi, AppLanguage.gujarati]) {
        for (final phrase in phrases) {
          expect(
            AppLocalizer.text(phrase, locale: language.locale),
            isNot(phrase),
            reason: '$phrase must be translated for ${language.code}',
          );
        }
      }
    });

    test('keeps user-entered or unknown business data unchanged', () {
      const businessData = 'Creovo MDF';
      expect(
        AppLocalizer.text(businessData, locale: AppLanguage.hindi.locale),
        businessData,
      );
      expect(
        AppLocalizer.text(businessData, locale: AppLanguage.gujarati.locale),
        businessData,
      );
    });

    test('translates count and selection patterns', () {
      expect(
        AppLocalizer.text('4 Customers', locale: AppLanguage.hindi.locale),
        '4 ग्राहक',
      );
      expect(
        AppLocalizer.text('Invoices (6)', locale: AppLanguage.gujarati.locale),
        'ઇન્વૉઇસ (6)',
      );
      expect(
        AppLocalizer.text('Select Customer', locale: AppLanguage.hindi.locale),
        'चुनें ग्राहक',
      );
      expect(
        AppLocalizer.text(
          '₹3,214 is still waiting to be collected',
          locale: AppLanguage.gujarati.locale,
        ),
        '₹3,214 હજુ વસૂલ કરવાનું બાકી છે',
      );
      expect(
        AppLocalizer.text('5 most recent', locale: AppLanguage.gujarati.locale),
        '5 સૌથી તાજેતરના',
      );
      expect(
        AppLocalizer.text('August cash flow', locale: AppLanguage.hindi.locale),
        'August नकदी प्रवाह',
      );
    });

    test('translates dashboard and form copy that previously fell back', () {
      const phrases = [
        'Good afternoon',
        'Create and manage your business',
        'Estimate',
        'View all',
        'Customer name *',
        'Save payment',
        'Create product',
      ];
      for (final language in [AppLanguage.hindi, AppLanguage.gujarati]) {
        for (final phrase in phrases) {
          expect(
            AppLocalizer.text(phrase, locale: language.locale),
            isNot(phrase),
          );
        }
      }
    });
  });
}
