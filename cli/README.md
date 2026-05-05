# CLI

The `cli/` package contains the Dart command-line tool exposed as `flutter_factory`.

Its role is to provide a developer-friendly interface over Mason bricks, validate user input, run environment checks, and generate apps or feature modules with consistent defaults.

Current commands:

- `flutter_factory create <app_name>`: creates a new Flutter project from the starter brick.
- `flutter_factory add feature <name>`: adds a feature-first Clean Architecture module.
- `flutter_factory add api <name> --endpoint <endpoint>`: adds Dio service, Freezed model, repository, use cases, and Riverpod providers.
- `flutter_factory add page <name> --feature <feature_name>`: adds a page inside a feature.
- `flutter_factory config`: runs interactive setup for state management, backend, auth, and offline defaults.

## Local Development Usage

The CLI can be used without publishing anything to BrickHub.

From the repository root:

```bash
dart pub global activate --source path cli
export FLUTTER_FACTORY_ROOT="$(pwd)"
```

Then run:

```bash
flutter_factory create my_app --state riverpod --auth --offline
flutter_factory add feature auth --state riverpod
flutter_factory add api auth --endpoint /v1/auth
flutter_factory add page login --feature auth
```

For one-off usage without global activation:

```bash
dart run cli/bin/flutter_factory.dart create my_app --state riverpod --auth --offline
```

`FLUTTER_FACTORY_ROOT` should point to the repository root that contains `mason.yaml`, `starter/`, `bricks/`, and `cli/`.

Expected core files:

- `pubspec.yaml`: Dart package metadata, CLI executable mapping, and CLI dependencies.
- `bin/flutter_factory.dart`: executable entry point used by `dart pub global activate`.
- `lib/src/command_runner.dart`: top-level command runner configuration.
- `lib/src/commands/`: command implementations such as `create`, `add`, and `config`.
- `lib/src/config/`: CLI configuration, defaults, and project discovery helpers.
- `lib/src/generator/`: Mason integration layer that invokes local or remote bricks.
- `test/`: command and generator behavior tests.
