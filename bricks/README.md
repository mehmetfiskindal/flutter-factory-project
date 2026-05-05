# Bricks

The `bricks/` directory contains all Mason bricks used by `flutter_factory`.

Each brick should be small, focused, and architecture-aware. Bricks should generate production-ready code that matches the Clean Architecture and feature-first conventions documented in this repository.

## Local Usage

These bricks can be used without publishing to BrickHub.

From the repository root, use the local brick registry:

```bash
mason get
mason make feature --name auth --state_management riverpod
mason make api_service --name auth --endpoint /v1/auth
```

Or add a single brick manually from a local path:

```bash
mason add feature --path bricks/feature
mason make feature --name auth --state_management riverpod
```

Expected structure per brick:

- `brick.yaml`: Mason metadata, variables, and description.
- `__brick__/`: generated file templates.
- `hooks/`: optional pre-generation and post-generation Dart hooks.
- `README.md`: usage notes and example generated output for that brick.
- `test/`: optional generation tests for important output.

Current planned bricks:

- `feature/`: creates a full feature module with Riverpod or Bloc presentation scaffolding.
- `page/`: creates a page inside an existing feature.
- `api_service/`: creates Dio-based API service scaffolding.
- `usecase/`: creates a domain use case.
- `widget/`: creates reusable feature or shared widgets.
