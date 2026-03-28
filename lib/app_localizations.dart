import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return value ?? const AppLocalizations(Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  bool get isSpanish => locale.languageCode.toLowerCase() == 'es';

  String get appTitle => isSpanish ? 'SampleCalc' : 'SampleCalc';

  String get history => isSpanish ? 'Historial' : 'History';
  String get settings => isSpanish ? 'Ajustes' : 'Settings';
  String get clear => isSpanish ? 'Borrar' : 'Clear';
  String get noHistoryYet => isSpanish ? 'Sin historial' : 'No history yet';
  String get copied => isSpanish ? 'Copiado' : 'Copied';

  String get angleMode => isSpanish ? 'Modo de ángulo' : 'Angle mode';
  String get precision => isSpanish ? 'Precisión' : 'Precision';
  String precisionWithValue(int v) => isSpanish ? 'Precisión ($v)' : 'Precision ($v)';
  String get apply => isSpanish ? 'Aplicar' : 'Apply';

  String get language => isSpanish ? 'Idioma' : 'Language';
  String get system => isSpanish ? 'Sistema' : 'System';
  String get english => isSpanish ? 'Inglés' : 'English';
  String get spanish => isSpanish ? 'Español' : 'Spanish';

  String get tooltipHistory => isSpanish ? 'Historial' : 'History';
  String get tooltipSettings => isSpanish ? 'Ajustes' : 'Settings';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
