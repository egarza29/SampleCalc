import 'package:flutter_test/flutter_test.dart';
import 'package:sample_calc/calculator_engine.dart';

void main() {
  group('CalculatorEngine', () {
    test('basic arithmetic', () {
      final engine = CalculatorEngine(settings: const CalculatorSettings(angleMode: AngleMode.rad, precision: 10));
      expect(engine.evaluate('2+2'), 4);
      expect(engine.evaluate('10-3'), 7);
      expect(engine.evaluate('6*7'), 42);
      expect(engine.evaluate('8/2'), 4);
    });

    test('right associative exponentiation', () {
      final engine = CalculatorEngine(settings: const CalculatorSettings(angleMode: AngleMode.rad, precision: 10));
      expect(engine.evaluate('2^3^2'), 512);
    });

    test('factorial', () {
      final engine = CalculatorEngine(settings: const CalculatorSettings(angleMode: AngleMode.rad, precision: 10));
      expect(engine.evaluate('5!'), 120);
      expect(engine.evaluate('3!+2'), 8);
    });

    test('functions and constants', () {
      final engine = CalculatorEngine(settings: const CalculatorSettings(angleMode: AngleMode.deg, precision: 10));
      expect(engine.evaluate('sin(90)'), closeTo(1, 1e-10));
      expect(engine.evaluate('cos(60)'), closeTo(0.5, 1e-10));
      expect(engine.evaluate('sqrt(16)'), 4);
      expect(engine.evaluate('max(1,2,3)'), 3);
      expect(engine.evaluate('min(1,2,3)'), 1);
      expect(engine.evaluate('pi'), closeTo(3.141592653589793, 1e-10));
    });

    test('implicit multiplication', () {
      final engine = CalculatorEngine(settings: const CalculatorSettings(angleMode: AngleMode.deg, precision: 10));
      expect(engine.evaluate('2(3+4)'), 14);
      expect(engine.evaluate('(1+2)(3+4)'), 21);
      expect(engine.evaluate('2pi'), closeTo(2 * 3.141592653589793, 1e-10));
      expect(engine.evaluate('2sin(30)'), closeTo(1, 1e-10));
      expect(engine.evaluate('sin(30)cos(60)'), closeTo(0.25, 1e-10));
    });

    test('scientific notation and constant e', () {
      final engine = CalculatorEngine(settings: const CalculatorSettings(angleMode: AngleMode.rad, precision: 12));
      expect(engine.evaluate('2e3'), 2000);
      expect(engine.evaluate('1.2e-2'), closeTo(0.012, 1e-12));
      expect(engine.evaluate('2e'), closeTo(2 * 2.718281828459045, 1e-12));
    });

    test('errors', () {
      final engine = CalculatorEngine(settings: const CalculatorSettings(angleMode: AngleMode.rad, precision: 10));
      expect(() => engine.evaluate('1/0'), throwsA(isA<StateError>()));
      expect(() => engine.evaluate('sqrt(-1)'), throwsA(isA<StateError>()));
      expect(() => engine.evaluate('unknown(1)'), throwsA(isA<FormatException>()));
    });
  });
}
