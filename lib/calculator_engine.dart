import 'dart:math' as math;

enum AngleMode { deg, rad }

class CalculatorSettings {
  final AngleMode angleMode;
  final int precision;
  const CalculatorSettings({this.angleMode = AngleMode.rad, this.precision = 10});
}

class Memory {
  double _value = 0.0;
  double get value => _value;
  void clear() => _value = 0.0;
  void set(double v) => _value = v;
  void add(double v) => _value += v;
  void subtract(double v) => _value -= v;
}

class CalculatorEngine {
  CalculatorSettings settings;
  final Memory memory = Memory();
  final List<String> _history = [];

  CalculatorEngine({CalculatorSettings? settings})
      : settings = settings ?? const CalculatorSettings();

  List<String> get history => List.unmodifiable(_history);

  double evaluate(String expression) {
    if (expression.trim().isEmpty) return 0.0;
    final tokens = _insertImplicitMultiplication(_tokenize(expression));
    final rpn = _toRpn(tokens);
    final result = _evalRpn(rpn);
    final rounded = _round(result, settings.precision);
    _history.add('$expression = $rounded');
    return rounded;
  }

  void clearHistory() {
    _history.clear();
  }

  void updateSettings(CalculatorSettings newSettings) {
    settings = newSettings;
  }

  double _round(double v, int precision) {
    final p = math.pow(10, precision).toDouble();
    return (v * p).roundToDouble() / p;
  }

  // Tokenization
  List<_Token> _tokenize(String s) {
    final tokens = <_Token>[];
    int i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (_isSpace(ch)) {
        i++;
        continue;
      }
      if (_isDigit(ch) || ch == '.') {
        final start = i;
        var hasDot = ch == '.';
        i++;
        while (i < s.length && (_isDigit(s[i]) || (s[i] == '.' && !hasDot))) {
          hasDot = hasDot || s[i] == '.';
          i++;
        }
        if (i < s.length && (s[i] == 'e' || s[i] == 'E') && _looksLikeExponent(s, i + 1)) {
          i++;
          if (i < s.length && (s[i] == '+' || s[i] == '-')) {
            i++;
          }
          while (i < s.length && _isDigit(s[i])) {
            i++;
          }
        }
        tokens.add(_Token.number(double.parse(s.substring(start, i))));
        continue;
      }
      if (_isAlpha(ch) || ch == '_') {
        final start = i;
        i++;
        while (i < s.length && (_isAlphaNum(s[i]) || s[i] == '_')) {
          i++;
        }
        final ident = s.substring(start, i);
        tokens.add(_Token.ident(ident));
        continue;
      }
      if ('+-*/^%!(),'.contains(ch)) {
        tokens.add(_Token.symbol(ch));
        i++;
        continue;
      }
      throw FormatException('Invalid character: $ch');
    }
    return tokens;
  }

  List<_Token> _insertImplicitMultiplication(List<_Token> tokens) {
    final out = <_Token>[];
    for (var i = 0; i < tokens.length; i++) {
      final a = tokens[i];
      out.add(a);
      if (i == tokens.length - 1) break;
      final b = tokens[i + 1];

      final leftIsFactor = _isImplicitLeftFactor(a);
      final rightIsFactor = _isImplicitRightFactor(b);

      final aIsFuncName = a.type == _TokenType.ident && _isFunction(a.ident!);
      final bIsLParen = b.type == _TokenType.symbol && b.sym == '(';
      final isFunctionCall = aIsFuncName && bIsLParen;

      if (leftIsFactor && rightIsFactor && !isFunctionCall) {
        out.add(_Token.symbol('*'));
      }
    }
    return out;
  }

  bool _isImplicitLeftFactor(_Token t) {
    if (t.type == _TokenType.number) return true;
    if (t.type == _TokenType.ident) return _isConstant(t.ident!);
    if (t.type == _TokenType.symbol) return t.sym == ')' || t.sym == '!';
    return false;
  }

  bool _isImplicitRightFactor(_Token t) {
    if (t.type == _TokenType.number) return true;
    if (t.type == _TokenType.ident) return _isConstant(t.ident!) || _isFunction(t.ident!);
    if (t.type == _TokenType.symbol) return t.sym == '(';
    return false;
  }

  // Shunting Yard to RPN
  List<_RpnEntry> _toRpn(List<_Token> tokens) {
    final output = <_RpnEntry>[];
    final stack = <_StackEntry>[];
    String? prevType;
    final argCounts = <int>[];
    final callFrames = <bool>[];

    for (final t in tokens) {
      switch (t.type) {
        case _TokenType.number:
          output.add(_RpnEntry.number(t.num!));
          prevType = 'VALUE';
          break;
        case _TokenType.ident:
          if (_isConstant(t.ident!)) {
            output.add(_RpnEntry.number(_getConstant(t.ident!)));
            prevType = 'VALUE';
          } else if (_isFunction(t.ident!)) {
            stack.add(_StackEntry.func(t.ident!));
            argCounts.add(1);
            prevType = 'FUNC';
          } else {
            throw FormatException('Unknown identifier: ${t.ident}');
          }
          break;
        case _TokenType.symbol:
          final sym = t.sym!;
          if (sym == '(') {
            callFrames.add(stack.isNotEmpty && stack.last.isFunc);
            stack.add(_StackEntry.lparen());
            prevType = 'LPAREN';
          } else if (sym == ')') {
            while (stack.isNotEmpty && !stack.last.isLParen) {
              output.add(_RpnEntry.op(stack.removeLast().op!));
            }
            if (stack.isEmpty) throw FormatException('Unbalanced parentheses');
            final isFuncCall = callFrames.isNotEmpty ? callFrames.removeLast() : false;
            stack.removeLast(); // pop '('
            if (isFuncCall) {
              if (stack.isEmpty || !stack.last.isFunc) {
                throw FormatException('Function call missing name');
              }
              final func = stack.removeLast();
              final argc = prevType == 'LPAREN' ? 0 : (argCounts.isNotEmpty ? argCounts.removeLast() : 1);
              output.add(_RpnEntry.func(func.funcName!, argc));
            }
            prevType = 'RPAREN';
          } else if (sym == ',') {
            if (callFrames.isEmpty || !callFrames.last) {
              throw FormatException('Misplaced comma');
            }
            while (stack.isNotEmpty && !stack.last.isLParen) {
              output.add(_RpnEntry.op(stack.removeLast().op!));
            }
            if (argCounts.isEmpty) {
              throw FormatException('Misplaced comma');
            }
            argCounts[argCounts.length - 1]++;
          } else if ('+-*/^%!'.contains(sym)) {
            var op = sym;
            if (op == '-' && (prevType == null || prevType == 'OP' || prevType == 'LPAREN' || prevType == 'FUNC')) {
              op = 'u-';
            }
            while (stack.isNotEmpty && stack.last.isOp) {
              final top = stack.last.op!;
              if (_shouldPop(top, op)) {
                output.add(_RpnEntry.op(stack.removeLast().op!));
              } else {
                break;
              }
            }
            stack.add(_StackEntry.op(op));
            prevType = 'OP';
          }
          break;
      }
    }
    while (stack.isNotEmpty) {
      final top = stack.removeLast();
      if (top.isLParen) throw FormatException('Unbalanced parentheses');
      if (top.isFunc) {
        throw FormatException('Function call missing parentheses: ${top.funcName}');
      }
      if (top.op == null) throw FormatException('Invalid operator');
      output.add(_RpnEntry.op(top.op!));
    }
    return output;
  }

  bool _shouldPop(String top, String incoming) {
    final pTop = _precedence(top);
    final pIn = _precedence(incoming);
    if (pTop > pIn) return true;
    if (pTop == pIn && !_isRightAssoc(incoming)) return true;
    return false;
  }

  int _precedence(String op) {
    switch (op) {
      case '!':
        return 5;
      case '^':
        return 4;
      case 'u-':
        return 3;
      case '*':
      case '/':
      case '%':
        return 2;
      case '+':
      case '-':
        return 1;
      default:
        return 0;
    }
  }

  bool _isRightAssoc(String op) => op == '^';

  // Evaluate RPN
  double _evalRpn(List<_RpnEntry> rpn) {
    final stack = <double>[];
    for (final e in rpn) {
      if (e.isNumber) {
        stack.add(e.number!);
      } else if (e.isOp) {
        final op = e.op!;
        if (op == 'u-') {
          if (stack.isEmpty) throw StateError('Unary minus requires operand');
          final a = stack.removeLast();
          stack.add(-a);
        } else if (op == '!') {
          if (stack.isEmpty) throw StateError('Factorial requires operand');
          final a = stack.removeLast();
          if (a % 1 != 0 || a < 0) {
            throw StateError('Factorial expects non-negative integer');
          }
          stack.add(_factorial(a.toInt()).toDouble());
        } else {
          if (stack.length < 2) throw StateError('Operator $op requires two operands');
          final b = stack.removeLast();
          final a = stack.removeLast();
          switch (op) {
            case '+':
              stack.add(a + b);
              break;
            case '-':
              stack.add(a - b);
              break;
            case '*':
              stack.add(a * b);
              break;
            case '/':
              if (b == 0) throw StateError('Division by zero');
              stack.add(a / b);
              break;
            case '%':
              stack.add(a % b);
              break;
            case '^':
              stack.add(math.pow(a, b).toDouble());
              break;
            default:
              throw StateError('Unknown operator $op');
          }
        }
      } else if (e.isFunc) {
        final name = e.funcName!;
        final argc = e.argc!;
        if (stack.length < argc) throw StateError('Function $name requires $argc arguments');
        final args = List<double>.generate(argc, (_) => stack.removeLast()).reversed.toList();
        stack.add(_callFunction(name, args));
      }
    }
    if (stack.length != 1) throw StateError('Evaluation error');
    return stack.first;
  }

  double _callFunction(String name, List<double> args) {
    switch (name) {
      case 'sin':
        _requireArity(name, args, 1);
        return math.sin(_toRad(args[0]));
      case 'cos':
        _requireArity(name, args, 1);
        return math.cos(_toRad(args[0]));
      case 'tan':
        _requireArity(name, args, 1);
        return math.tan(_toRad(args[0]));
      case 'asin':
        _requireArity(name, args, 1);
        return _toAngle(math.asin(args[0]));
      case 'acos':
        _requireArity(name, args, 1);
        return _toAngle(math.acos(args[0]));
      case 'atan':
        _requireArity(name, args, 1);
        return _toAngle(math.atan(args[0]));
      case 'sqrt':
        _requireArity(name, args, 1);
        if (args[0] < 0) throw StateError('Domain error: sqrt of negative');
        return math.sqrt(args[0]);
      case 'abs':
        _requireArity(name, args, 1);
        return args[0].abs();
      case 'ln':
        _requireArity(name, args, 1);
        if (args[0] <= 0) throw StateError('Domain error: ln of non-positive');
        return math.log(args[0]);
      case 'log':
        _requireArity(name, args, 1);
        if (args[0] <= 0) throw StateError('Domain error: log10 of non-positive');
        return math.log(args[0]) / math.ln10;
      case 'min':
        if (args.isEmpty) throw StateError('Function min requires at least 1 argument');
        return args.reduce(math.min);
      case 'max':
        if (args.isEmpty) throw StateError('Function max requires at least 1 argument');
        return args.reduce(math.max);
      case 'round':
        _requireArity(name, args, 1);
        return args[0].roundToDouble();
      case 'floor':
        _requireArity(name, args, 1);
        return args[0].floorToDouble();
      case 'ceil':
        _requireArity(name, args, 1);
        return args[0].ceilToDouble();
      case 'pow':
        _requireArity(name, args, 2);
        return math.pow(args[0], args[1]).toDouble();
      default:
        throw StateError('Unknown function $name');
    }
  }

  void _requireArity(String name, List<double> args, int expected) {
    if (args.length != expected) {
      throw StateError('Function $name requires $expected arguments');
    }
  }

  double _toRad(double x) {
    return settings.angleMode == AngleMode.deg ? x * math.pi / 180.0 : x;
  }

  double _toAngle(double r) {
    return settings.angleMode == AngleMode.deg ? r * 180.0 / math.pi : r;
  }

  bool _isConstant(String name) => name == 'pi' || name == 'e';
  double _getConstant(String name) =>
      name == 'pi' ? math.pi : (name == 'e' ? math.e : double.nan);
  bool _isFunction(String name) {
    const funcs = {
      'sin',
      'cos',
      'tan',
      'asin',
      'acos',
      'atan',
      'sqrt',
      'abs',
      'ln',
      'log',
      'min',
      'max',
      'round',
      'floor',
      'ceil',
      'pow',
    };
    return funcs.contains(name);
  }

  int _factorial(int n) {
    var r = 1;
    for (var i = 2; i <= n; i++) {
      r *= i;
    }
    return r;
  }
}

enum _TokenType { number, ident, symbol }

class _Token {
  final _TokenType type;
  final double? num;
  final String? ident;
  final String? sym;
  _Token.number(this.num)
      : type = _TokenType.number,
        ident = null,
        sym = null;
  _Token.ident(this.ident)
      : type = _TokenType.ident,
        num = null,
        sym = null;
  _Token.symbol(String ch)
      : type = _TokenType.symbol,
        num = null,
        ident = null,
        sym = ch;
}

class _RpnEntry {
  final double? number;
  final String? op;
  final String? funcName;
  final int? argc;
  _RpnEntry.number(this.number)
      : op = null,
        funcName = null,
        argc = null;
  _RpnEntry.op(this.op)
      : number = null,
        funcName = null,
        argc = null;
  _RpnEntry.func(this.funcName, this.argc)
      : number = null,
        op = null;
  bool get isNumber => number != null;
  bool get isOp => op != null;
  bool get isFunc => funcName != null;
}

class _StackEntry {
  final String? op;
  final String? funcName;
  final bool isLParen;
  final bool isFunc;
  final bool isOp;
  _StackEntry._(this.op, this.funcName, this.isLParen, this.isFunc, this.isOp);
  factory _StackEntry.op(String o) => _StackEntry._(o, null, false, false, true);
  factory _StackEntry.func(String f) => _StackEntry._(null, f, false, true, false);
  factory _StackEntry.lparen() => _StackEntry._(null, null, true, false, false);
}

bool _isSpace(String ch) => ch.trim().isEmpty;
bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
bool _isAlpha(String ch) {
  final c = ch.codeUnitAt(0);
  return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
}

bool _isAlphaNum(String ch) => _isAlpha(ch) || _isDigit(ch);

bool _looksLikeExponent(String s, int index) {
  if (index >= s.length) return false;
  final ch = s[index];
  if (_isDigit(ch)) return true;
  if ((ch == '+' || ch == '-') && index + 1 < s.length && _isDigit(s[index + 1])) {
    return true;
  }
  return false;
}
