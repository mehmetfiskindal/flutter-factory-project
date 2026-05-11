# CLI Reference

## Local Verification

Use `flutter_factory verify` to check starter generation on your machine without
GitHub Actions or hosted CI.

```bash
flutter_factory verify
flutter_factory verify --full
flutter_factory verify --no-analyze
```

- Default mode generates four representative starter combinations.
- `--full` generates all state/backend/auth/offline combinations.
- `--no-analyze` skips `flutter pub get` and `flutter analyze`.

## Page Routes

`add page` generates a view, controller, route file, and wires the route into
starter router files when flutter-factory markers are present.

```bash
flutter_factory add page dashboard --feature profile
flutter_factory add page activity_log --feature profile --path /profile/activity
flutter_factory add page draft --feature profile --no-route
```

- `--path` changes the generated route path.
- `--no-route` keeps the files generated but skips router edits.
