# Monorepo Structure

flutter-factory is organized as a small monorepo so the CLI, Mason bricks, starter template, shared packages, and documentation can evolve together.

```text
flutter-factory/
├── cli/
├── bricks/
│   ├── feature/
│   ├── page/
│   ├── api_service/
│   ├── usecase/
│   └── widget/
├── starter/
├── packages/
├── docs/
├── mason.yaml
└── README.md
```

## `cli/`

The `cli/` directory is the Dart command-line application published or activated as `flutter_factory`.

Its responsibility is to make generation simple and consistent. It should parse commands, validate arguments, check the developer environment, select the right Mason brick, pass variables into Mason, and display useful output.

Core files expected inside `cli/`:

- `pubspec.yaml`: package metadata, dependencies, and executable mapping.
- `bin/flutter_factory.dart`: executable entry point.
- `lib/src/command_runner.dart`: root command runner.
- `lib/src/commands/create_command.dart`: app generation command.
- `lib/src/commands/add_command.dart`: feature, API, and page generation command.
- `lib/src/commands/config_command.dart`: interactive defaults setup command.
- `lib/src/generator/mason_service.dart`: Mason invocation adapter.
- `lib/src/config/flutter_factory_config.dart`: defaults and project-level config.
- `test/`: command parsing and generator integration tests.

## `bricks/`

The `bricks/` directory contains all Mason bricks consumed by the CLI.

Each brick should generate one focused part of a Flutter project. Bricks should avoid hidden architecture decisions; the CLI should pass explicit variables so generated output remains predictable.

Core files expected inside `bricks/`:

- `pubspec.yaml`: tooling package for shared hook dependencies, brick tests, and validation utilities.
- `README.md`: overview of available bricks.
- `<brick_name>/brick.yaml`: Mason metadata and variables.
- `<brick_name>/__brick__/`: template files generated into the target project.
- `<brick_name>/hooks/`: optional pre-generation and post-generation Dart hooks.
- `<brick_name>/README.md`: brick-specific usage examples.
- `<brick_name>/test/`: output tests for complex bricks.

Planned bricks:

- `feature/`: creates `data`, `domain`, and `presentation` layers for a feature.
- `page/`: creates a Flutter page and optional state binding inside a feature.
- `api_service/`: creates Dio service scaffolding in the feature data layer.
- `usecase/`: creates a domain use case and matching test placeholder.
- `widget/`: creates reusable widgets with naming and folder conventions.

## `starter/`

The `starter/` directory contains the base Flutter app template used by `flutter_factory create`.

It should be the foundation of every generated app: dependencies, app bootstrap, routing, theme, networking setup, analysis options, and initial test structure.

Core files expected inside `starter/`:

- `pubspec.yaml`: default app dependencies.
- `analysis_options.yaml`: linting rules.
- `lib/main.dart`: Flutter entry point.
- `lib/app/`: root app widget and bootstrap.
- `lib/core/`: routing, network, config, errors, constants, and utilities.
- `lib/features/`: generated feature destination and optional sample feature.
- `test/`: baseline tests.
- Platform folders generated or copied according to the selected target platforms.

## `packages/`

The `packages/` directory is for shared internal packages.

Use this directory when logic is reused by the CLI, starter template, tests, or generated apps. Keep these packages small and stable so generated projects do not inherit unnecessary complexity.

Potential packages:

- `core`: shared abstractions, result types, error models, and contracts.
- `utils`: string helpers, naming helpers, file helpers, and small extensions.
- `testing`: generator tests, fixture helpers, and golden output utilities.
- `lint_rules`: shared lint configuration.

## `docs/`

The `docs/` directory contains contributor and user documentation.

It should explain not only how to run commands, but also why generated projects are structured in a specific way.

Core files expected inside `docs/`:

- `cli.md`: command reference.
- `bricks.md`: brick authoring and usage guide.
- `architecture.md`: Clean Architecture and feature-first conventions.
- `starter-template.md`: starter app behavior and stack decisions.
- `contributing.md`: contribution workflow.
- `assets/demo.gif`: README demo placeholder target.

## `README.md`

The root README is the project landing page.

It should stay high-level and product-focused: what flutter-factory is, why it exists, how to install it, how to use it, supported stack, roadmap, and contribution guidance.

Detailed implementation notes should live in `docs/`.

## `mason.yaml`

The root `mason.yaml` registers local bricks for development.

It allows contributors to run Mason directly during brick development while the CLI is still being built.
