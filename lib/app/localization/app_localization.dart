import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'generated_translation_maps.dart';
import 'coverage_translation_maps.dart';

enum AppLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'Hindi', 'हिन्दी'),
  gujarati('gu', 'Gujarati', 'ગુજરાતી');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  final String code;
  final String englishName;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? value) => values.firstWhere(
    (language) => language.code == value,
    orElse: () => AppLanguage.english,
  );
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': {for (final key in _allKeys) key: key},
    'hi': {...appHindiCoverageTranslations, ...appHindiTranslations},
    'gu': {...appGujaratiCoverageTranslations, ...appGujaratiTranslations},
  };
}

final Set<String> _allKeys = {
  ...appHindiCoverageTranslations.keys,
  ...appHindiTranslations.keys,
  ...appGujaratiCoverageTranslations.keys,
  ...appGujaratiTranslations.keys,
};

abstract final class AppLocalizer {
  static String text(String? value, {Locale? locale}) {
    if (value == null || value.isEmpty) return value ?? '';
    final code = (locale ?? Get.locale)?.languageCode ?? 'en';
    if (code == 'en') return value;
    final translations = code == 'gu'
        ? {...appGujaratiCoverageTranslations, ...appGujaratiTranslations}
        : {...appHindiCoverageTranslations, ...appHindiTranslations};
    final exact = translations[value];
    if (exact != null) return exact;
    return _translateParameterized(value, translations);
  }

  static String _translateParameterized(
    String value,
    Map<String, String> translations,
  ) {
    final countPattern = RegExp(r'^(\d+)\s+(.+)$');
    final match = countPattern.firstMatch(value);
    if (match != null) {
      final translated = translations[match.group(2)!];
      if (translated != null) return '${match.group(1)} $translated';
    }
    const translatedSuffixes = [
      'is still waiting to be collected',
      'most recent',
      'cash flow',
      'remaining',
      'entries',
      'invoices created',
      'saved items',
      'recommendations · all optional',
      'active',
      'field',
      'vs last period',
      'from last period',
      'collected',
    ];
    for (final suffix in translatedSuffixes) {
      final marker = ' $suffix';
      if (!value.endsWith(marker)) continue;
      final translated = translations[suffix];
      if (translated != null) {
        return '${value.substring(0, value.length - marker.length)} $translated';
      }
    }
    final parenthesized = RegExp(r'^(.+?)\s*\((\d+)\)$').firstMatch(value);
    if (parenthesized != null) {
      final translated = translations[parenthesized.group(1)!.trim()];
      if (translated != null) return '$translated (${parenthesized.group(2)})';
    }
    for (final prefix in ['Select ', 'Add ', 'Change ', 'Search ']) {
      if (!value.startsWith(prefix)) continue;
      final translatedPrefix = translations[prefix.trim()];
      final translatedValue = translations[value.substring(prefix.length)];
      if (translatedPrefix != null && translatedValue != null) {
        return '$translatedPrefix $translatedValue';
      }
    }
    return value;
  }

  static InlineSpan span(InlineSpan span, {Locale? locale}) {
    if (span is! TextSpan) return span;
    return TextSpan(
      text: span.text == null ? null : text(span.text, locale: locale),
      children: span.children
          ?.map((child) => AppLocalizer.span(child, locale: locale))
          .toList(),
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel == null
          ? null
          : text(span.semanticsLabel, locale: locale),
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}
