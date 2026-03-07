import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  final Map<String, Map<String, String>> _voiceByLocale =
      <String, Map<String, String>>{};

  bool _voiceCatalogLoaded = false;
  String? _lastConfiguredLocale;

  TTSService() {
    _initialize();
  }

  Future<void> speak(String text, {required String locale}) async {
    await _configureLocaleVoice(locale);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  Future<void> _initialize() async {
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _configureLocaleVoice('en-US');
  }

  Future<void> _configureLocaleVoice(String locale) async {
    if (_lastConfiguredLocale == locale) {
      return;
    }

    await _tts.setLanguage(locale);
    await _loadVoiceCatalog();

    final voice = _voiceByLocale[locale];
    if (voice != null) {
      await _tts.setVoice(voice);
    }

    _lastConfiguredLocale = locale;
  }

  Future<void> _loadVoiceCatalog() async {
    if (_voiceCatalogLoaded) {
      return;
    }

    final dynamic raw = await _tts.getVoices;
    if (raw is! List) {
      _voiceCatalogLoaded = true;
      return;
    }

    final voices = raw.whereType<Map>().toList(growable: false);
    final selectedEn = _pickBestVoice(
      voices,
      localeAliases: const <String>['en-US', 'en_US'],
    );
    if (selectedEn != null) {
      _voiceByLocale['en-US'] = selectedEn;
    }

    final selectedPt = _pickBestVoice(
      voices,
      localeAliases: const <String>['pt-BR', 'pt_BR'],
    );
    if (selectedPt != null) {
      _voiceByLocale['pt-BR'] = selectedPt;
    }

    _voiceCatalogLoaded = true;
  }

  Map<String, String>? _pickBestVoice(
    List<Map> voices, {
    required List<String> localeAliases,
  }) {
    Map<String, String>? bestVoice;
    var bestScore = -1;

    for (final rawVoice in voices) {
      final name = (rawVoice['name'] ?? '').toString();
      final locale = (rawVoice['locale'] ?? '').toString();
      if (name.isEmpty || locale.isEmpty) {
        continue;
      }

      final normalizedLocale = locale.replaceAll('-', '_').toLowerCase();
      final localeMatch = localeAliases.any((alias) {
        final normalizedAlias = alias.replaceAll('-', '_').toLowerCase();
        return normalizedLocale.startsWith(normalizedAlias);
      });
      if (!localeMatch) {
        continue;
      }

      var score = 10;
      final loweredName = name.toLowerCase();
      if (loweredName.contains('neural') ||
          loweredName.contains('network') ||
          loweredName.contains('wavenet') ||
          loweredName.contains('natural')) {
        score += 30;
      }
      if (loweredName.contains('premium') || loweredName.contains('enhanced')) {
        score += 10;
      }
      if (loweredName.contains('legacy') || loweredName.contains('classic')) {
        score -= 10;
      }

      if (score > bestScore) {
        bestScore = score;
        bestVoice = <String, String>{
          'name': name,
          'locale': locale,
        };
      }
    }

    return bestVoice;
  }
}
