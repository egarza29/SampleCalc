# Architecture

## Modules
- Tokenizer: Converts input to tokens.
- Parser (Shunting Yard): Produces RPN using precedence/associativity.
- Evaluator: Executes RPN with a numeric stack.
- Registry: Functions/operators/constants mapping.
- State: Angle mode, precision, memory, history.

## Data Flow
Expression → Tokenizer → Parser (RPN) → Evaluator → Result (+ history)

## Extensibility
- Register custom functions/operators.
- Feature flags for modes and precision.
- Future support for complex numbers via pluggable backend.

## Platform
- Flutter UI layer calls pure Dart engine.
- Store packaging per platform via standard tooling.
