# UI Specification

## Screens
- Calculator: display area (expression + result), keypad grid, memory actions.
- History: bottom sheet list of previous evaluations; tap to load; clear history.
- Settings: bottom sheet for angle mode (DEG/RAD) and precision (0–12).

## Keypad
- Digits: 0–9
- Operators: + - * / % ^ ( ) = !
- Edit: C (clear all), CE (clear entry), ⌫ (backspace), ANS
- Functions: sin cos tan asin acos atan sqrt ln log abs min max pow
- Constants: pi, e
- Memory: M+, M-, MR, MC

## Behaviors
- Evaluate on "="; show error message on exceptions.
- Append function names with "(" automatically for direct input.
- Theme: Material, seed color indigo; dark/light auto.
- Keyboard input supported on desktop: digits/operators, Enter for "=", Backspace for "⌫", Delete for "CE", Escape for "C".

## Localization
- UI supports English and Spanish.
- Default language follows device locale; user can override from Settings.
- Numbers use locale-friendly separators:
  - English: decimal ".", list separator "," (function arguments).
  - Spanish: decimal ",", list separator ";" (function arguments).

## Accessibility
- Large targets, labels, and semantic roles for controls.
