import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'calculator_engine.dart';
import 'app_localizations.dart';

void main() {
  runApp(const SampleCalcApp());
}

class SampleCalcApp extends StatefulWidget {
  const SampleCalcApp({super.key});
  @override
  State<SampleCalcApp> createState() => _SampleCalcAppState();
}

class _SampleCalcAppState extends State<SampleCalcApp> {
  Locale? _localeOverride;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SampleCalc',
      locale: _localeOverride,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: CalculatorPage(
        localeOverride: _localeOverride,
        onLocaleChanged: (v) => setState(() => _localeOverride = v),
      ),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  final Locale? localeOverride;
  final ValueChanged<Locale?> onLocaleChanged;
  const CalculatorPage({super.key, required this.localeOverride, required this.onLocaleChanged});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _engine = CalculatorEngine(
    settings: const CalculatorSettings(angleMode: AngleMode.deg, precision: 10),
  );
  String _expression = '';
  String _result = '0';
  String? _error;

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).copied)),
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l = AppLocalizations.of(context);
        var angle = _engine.settings.angleMode;
        var precision = _engine.settings.precision;
        Locale? localeOverride = widget.localeOverride;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.settings, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(l.angleMode),
                        const Spacer(),
                        DropdownButton<AngleMode>(
                          value: angle,
                          items: const [
                            DropdownMenuItem(value: AngleMode.deg, child: Text('DEG')),
                            DropdownMenuItem(value: AngleMode.rad, child: Text('RAD')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => angle = v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(l.language),
                        const Spacer(),
                        DropdownButton<String>(
                          value: localeOverride?.languageCode ?? 'system',
                          items: [
                            DropdownMenuItem(value: 'system', child: Text(l.system)),
                            DropdownMenuItem(value: 'en', child: Text(l.english)),
                            DropdownMenuItem(value: 'es', child: Text(l.spanish)),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() {
                              localeOverride = v == 'system' ? null : Locale(v);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(l.precisionWithValue(precision)),
                        const Spacer(),
                      ],
                    ),
                    Slider(
                      min: 0,
                      max: 12,
                      divisions: 12,
                      value: precision.toDouble(),
                      onChanged: (v) => setModalState(() => precision = v.round()),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _engine.updateSettings(CalculatorSettings(angleMode: angle, precision: precision));
                          });
                          widget.onLocaleChanged(localeOverride);
                          Navigator.of(context).pop();
                        },
                        child: Text(l.apply),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l = AppLocalizations.of(context);
        final items = _engine.history.reversed.toList();
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(l.history, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _engine.clearHistory();
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text(l.clear),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(l.noHistoryYet))
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final line = items[i];
                          final parts = line.split(' = ');
                          final expr = parts.isNotEmpty ? parts.first : '';
                          final value = parts.length > 1 ? parts.last : '';
                          return ListTile(
                            title: Text(expr),
                            subtitle: Text(value),
                            onTap: () {
                              setState(() {
                                _expression = expr;
                                if (value.isNotEmpty) _result = value;
                                _error = null;
                              });
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleAngleMode() {
    final next = _engine.settings.angleMode == AngleMode.deg ? AngleMode.rad : AngleMode.deg;
    _engine.updateSettings(CalculatorSettings(angleMode: next, precision: _engine.settings.precision));
    setState(() {});
  }

  double? _valueForMemory() {
    if (_expression.trim().isEmpty) return double.tryParse(_result);
    return _engine.evaluate(_expression);
  }

  void _onPress(String k) {
    setState(() {
      _error = null;
      switch (k) {
        case 'C':
          _expression = '';
          _result = '0';
          break;
        case 'CE':
          _expression = '';
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          break;
        case '=':
          try {
            final r = _engine.evaluate(_expression);
            _result = r.toString();
          } catch (e) {
            _result = 'Error';
            _error = e.toString();
          }
          break;
        case 'M+':
          try {
            final v = _valueForMemory();
            if (v != null) _engine.memory.add(v);
            _result = _engine.memory.value.toString();
          } catch (e) {
            _result = 'Error';
            _error = e.toString();
          }
          break;
        case 'M-':
          try {
            final v = _valueForMemory();
            if (v != null) _engine.memory.subtract(v);
            _result = _engine.memory.value.toString();
          } catch (e) {
            _result = 'Error';
            _error = e.toString();
          }
          break;
        case 'MR':
          _expression += _engine.memory.value.toString();
          break;
        case 'MC':
          _engine.memory.clear();
          _result = '0';
          break;
        case 'ANS':
          _expression += _result;
          break;
        default:
          _expression += k;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final keys = [
      'sin(', 'cos(', 'tan(', 'asin(', 'acos(',
      'atan(', 'sqrt(', 'ln(', 'log(', 'abs(',
      'min(', 'max(', 'pow(', 'pi', 'e',
      '7', '8', '9', '/', 'C',
      '4', '5', '6', '*', '⌫',
      '1', '2', '3', '-', 'MC',
      '0', '.', ',', '+', '=',
      '(', ')', '^', '%', '!',
      'M+', 'M-', 'MR', 'ANS', 'CE',
    ];
    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.enter): const _KeyIntent('='),
          const SingleActivator(LogicalKeyboardKey.numpadEnter): const _KeyIntent('='),
          const SingleActivator(LogicalKeyboardKey.equal): const _KeyIntent('='),
          const SingleActivator(LogicalKeyboardKey.backspace): const _KeyIntent('⌫'),
          const SingleActivator(LogicalKeyboardKey.delete): const _KeyIntent('CE'),
          const SingleActivator(LogicalKeyboardKey.escape): const _KeyIntent('C'),
          const SingleActivator(LogicalKeyboardKey.period): const _KeyIntent('.'),
          const SingleActivator(LogicalKeyboardKey.comma): const _KeyIntent(','),
          const SingleActivator(LogicalKeyboardKey.minus): const _KeyIntent('-'),
          const SingleActivator(LogicalKeyboardKey.numpadSubtract): const _KeyIntent('-'),
          const SingleActivator(LogicalKeyboardKey.numpadAdd): const _KeyIntent('+'),
          const SingleActivator(LogicalKeyboardKey.slash): const _KeyIntent('/'),
          const SingleActivator(LogicalKeyboardKey.numpadDivide): const _KeyIntent('/'),
          const SingleActivator(LogicalKeyboardKey.numpadMultiply): const _KeyIntent('*'),
          const SingleActivator(LogicalKeyboardKey.digit8, shift: true): const _KeyIntent('*'),
          const SingleActivator(LogicalKeyboardKey.digit9, shift: true): const _KeyIntent('('),
          const SingleActivator(LogicalKeyboardKey.digit0, shift: true): const _KeyIntent(')'),
          const SingleActivator(LogicalKeyboardKey.digit5, shift: true): const _KeyIntent('%'),
          const SingleActivator(LogicalKeyboardKey.digit6, shift: true): const _KeyIntent('^'),
          const SingleActivator(LogicalKeyboardKey.digit0): const _KeyIntent('0'),
          const SingleActivator(LogicalKeyboardKey.digit1): const _KeyIntent('1'),
          const SingleActivator(LogicalKeyboardKey.digit2): const _KeyIntent('2'),
          const SingleActivator(LogicalKeyboardKey.digit3): const _KeyIntent('3'),
          const SingleActivator(LogicalKeyboardKey.digit4): const _KeyIntent('4'),
          const SingleActivator(LogicalKeyboardKey.digit5): const _KeyIntent('5'),
          const SingleActivator(LogicalKeyboardKey.digit6): const _KeyIntent('6'),
          const SingleActivator(LogicalKeyboardKey.digit7): const _KeyIntent('7'),
          const SingleActivator(LogicalKeyboardKey.digit8): const _KeyIntent('8'),
          const SingleActivator(LogicalKeyboardKey.digit9): const _KeyIntent('9'),
          const SingleActivator(LogicalKeyboardKey.numpad0): const _KeyIntent('0'),
          const SingleActivator(LogicalKeyboardKey.numpad1): const _KeyIntent('1'),
          const SingleActivator(LogicalKeyboardKey.numpad2): const _KeyIntent('2'),
          const SingleActivator(LogicalKeyboardKey.numpad3): const _KeyIntent('3'),
          const SingleActivator(LogicalKeyboardKey.numpad4): const _KeyIntent('4'),
          const SingleActivator(LogicalKeyboardKey.numpad5): const _KeyIntent('5'),
          const SingleActivator(LogicalKeyboardKey.numpad6): const _KeyIntent('6'),
          const SingleActivator(LogicalKeyboardKey.numpad7): const _KeyIntent('7'),
          const SingleActivator(LogicalKeyboardKey.numpad8): const _KeyIntent('8'),
          const SingleActivator(LogicalKeyboardKey.numpad9): const _KeyIntent('9'),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _KeyIntent: CallbackAction<_KeyIntent>(
              onInvoke: (intent) {
                _onPress(intent.key);
                return null;
              },
            ),
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(l.appTitle),
              actions: [
                IconButton(
                  onPressed: _showHistory,
                  icon: const Icon(Icons.history),
                  tooltip: l.tooltipHistory,
                ),
                IconButton(
                  onPressed: _showSettings,
                  icon: const Icon(Icons.settings),
                  tooltip: l.tooltipSettings,
                ),
                TextButton(
                  onPressed: _toggleAngleMode,
                  child: Text(
                    _engine.settings.angleMode == AngleMode.deg ? 'DEG' : 'RAD',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.black12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: SelectionArea(
                            child: Text(
                              _expression,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onLongPress: () => _copyToClipboard(_result),
                          child: SelectionArea(
                            child: Text(
                              _result,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (_engine.memory.value != 0.0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'M: ${_engine.memory.value}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            textAlign: TextAlign.end,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: keys.length,
                    itemBuilder: (_, i) {
                      final k = keys[i];
                      return ElevatedButton(
                        onPressed: () => _onPress(k),
                        child: Text(k, style: const TextStyle(fontSize: 16)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyIntent extends Intent {
  final String key;
  const _KeyIntent(this.key);
}
