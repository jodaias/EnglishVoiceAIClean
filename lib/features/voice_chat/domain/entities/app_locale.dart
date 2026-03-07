enum AppLocale { enUs, ptBr }

extension AppLocaleX on AppLocale {
  String get languageCode {
    switch (this) {
      case AppLocale.enUs:
        return 'en';
      case AppLocale.ptBr:
        return 'pt';
    }
  }

  String get countryCode {
    switch (this) {
      case AppLocale.enUs:
        return 'US';
      case AppLocale.ptBr:
        return 'BR';
    }
  }

  String get label {
    switch (this) {
      case AppLocale.enUs:
        return 'English';
      case AppLocale.ptBr:
        return 'Portugues (Brasil)';
    }
  }
}
