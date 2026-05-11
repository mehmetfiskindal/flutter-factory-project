import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_factory/flutter_factory.dart';
import 'package:flutter_factory/src/commands/config_command.dart';
import 'package:flutter_factory/src/commands/add_command.dart';
import 'package:flutter_factory/src/commands/create_command.dart';
import 'package:flutter_factory/src/commands/doctor_command.dart';
import 'package:flutter_factory/src/config/flutter_factory_config.dart';
import 'package:flutter_factory/src/generator/mason_service.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory previousDirectory;
  late Directory tempDirectory;

  setUp(() {
    previousDirectory = Directory.current;
    tempDirectory =
        Directory.systemTemp.createTempSync('flutter_factory_test_');
    Directory.current = tempDirectory;
  });

  tearDown(() {
    Directory.current = previousDirectory;
    tempDirectory.deleteSync(recursive: true);
  });

  test('prints version', () async {
    final exitCode = await runFlutterFactory(['--version']);

    expect(exitCode, 0);
  });

  test('create requires an app name', () async {
    final exitCode = await runFlutterFactory(['create']);

    expect(exitCode, 64);
  });

  test('add feature prevents existing feature conflicts by default', () async {
    Directory('lib/features/auth').createSync(recursive: true);

    final exitCode = await runFlutterFactory([
      'add',
      'feature',
      'auth',
    ]);

    expect(exitCode, 64);
  });

  test('add page prevents existing file conflicts by default', () async {
    File('lib/features/profile/presentation/views/dashboard_view.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('// existing');

    final exitCode = await runFlutterFactory([
      'add',
      'page',
      'dashboard',
      '--feature',
      'profile',
    ]);

    expect(exitCode, 64);
  });

  test('add page wires route constants and shell route markers', () async {
    _createGeneratedRouterFiles();
    final masonService = _RecordingMasonService();
    final runner = CommandRunner<int>('test', 'test')
      ..addCommand(
        AddPageCommand(
          logger: Logger(),
          masonService: masonService,
        ),
      );

    final exitCode = await runner.run([
      'page',
      'dashboard',
      '--feature',
      'profile',
    ]);

    expect(exitCode, 0);
    expect(masonService.brickName, 'page');
    expect(masonService.vars['name'], 'dashboard');
    expect(masonService.vars['feature'], 'profile');

    final routePaths = File(
      'lib/core/router/route_paths.dart',
    ).readAsStringSync();
    final router = File('lib/app/router.dart').readAsStringSync();

    expect(routePaths, contains("static const dashboard = '/dashboard';"));
    expect(routePaths, contains("static const dashboard = 'dashboard';"));
    expect(
      router,
      contains(
        "import '../features/profile/presentation/routes/dashboard_route.dart';",
      ),
    );
    expect(router, contains('DashboardRoute.route(),'));
  });

  test('add page route wiring is idempotent', () async {
    _createGeneratedRouterFiles();
    final masonService = _RecordingMasonService();
    final runner = CommandRunner<int>('test', 'test')
      ..addCommand(
        AddPageCommand(
          logger: Logger(),
          masonService: masonService,
        ),
      );

    for (var i = 0; i < 2; i += 1) {
      final exitCode = await runner.run([
        'page',
        'dashboard',
        '--feature',
        'profile',
        '--force',
      ]);
      expect(exitCode, 0);
    }

    final routePaths = File(
      'lib/core/router/route_paths.dart',
    ).readAsStringSync();
    final router = File('lib/app/router.dart').readAsStringSync();

    expect(
        _countOccurrences(routePaths, "static const dashboard = '/dashboard';"),
        1);
    expect(
      _countOccurrences(
        router,
        "import '../features/profile/presentation/routes/dashboard_route.dart';",
      ),
      1,
    );
    expect(_countOccurrences(router, 'DashboardRoute.route(),'), 1);
  });

  test('doctor command is available', () async {
    final exitCode = await runFlutterFactory(['doctor']);

    expect(exitCode, anyOf(0, 70));
  });

  test('create passes bloc state and firebase backend to the starter brick',
      () async {
    final masonService = _RecordingMasonService();
    final createdShells = <({String appName, String organization})>[];
    final runner = CommandRunner<int>('test', 'test')
      ..addCommand(
        CreateCommand(
          logger: Logger(),
          masonService: masonService,
          flutterShellCreator: ({
            required appName,
            required organization,
          }) async {
            createdShells.add((
              appName: appName,
              organization: organization,
            ));
          },
        ),
      );

    final exitCode = await runner.run([
      'create',
      'bloc_app',
      '--org',
      'com.example',
      '--state',
      'bloc',
      '--backend',
      'firebase',
    ]);

    expect(exitCode, 0);
    expect(createdShells.single.appName, 'bloc_app');
    expect(createdShells.single.organization, 'com.example');
    expect(masonService.brickName, 'starter');
    expect(masonService.targetDirectory, 'bloc_app');
    expect(masonService.force, isTrue);
    expect(masonService.vars['app_name'], 'bloc_app');
    expect(masonService.vars['org_name'], 'com.example');
    expect(masonService.vars['state_management'], 'bloc');
    expect(masonService.vars['backend'], 'firebase');
  });

  test('create passes auth and offline flags to the starter brick', () async {
    final masonService = _RecordingMasonService();
    final runner = CommandRunner<int>('test', 'test')
      ..addCommand(
        CreateCommand(
          logger: Logger(),
          masonService: masonService,
          flutterShellCreator: ({
            required appName,
            required organization,
          }) async {},
        ),
      );

    final exitCode = await runner.run([
      'create',
      'offline_auth_app',
      '--org',
      'com.example',
      '--auth',
      '--offline',
    ]);

    expect(exitCode, 0);
    expect(masonService.vars['auth'], isTrue);
    expect(masonService.vars['offline_support'], isTrue);
  });

  test('create CLI arguments override config defaults', () async {
    const config = FlutterFactoryConfig(
      stateManagement: 'bloc',
      backend: 'firebase',
      organization: 'com.config',
      auth: true,
      offline: true,
    );
    config.save();

    final masonService = _RecordingMasonService();
    final runner = CommandRunner<int>('test', 'test')
      ..addCommand(
        CreateCommand(
          logger: Logger(),
          masonService: masonService,
          flutterShellCreator: ({
            required appName,
            required organization,
          }) async {},
        ),
      );

    final exitCode = await runner.run([
      'create',
      'override_app',
      '--org',
      'com.cli',
      '--state',
      'riverpod',
      '--backend',
      'rest_firebase_hybrid',
      '--no-auth',
      '--no-offline',
    ]);

    expect(exitCode, 0);
    expect(masonService.vars['org_name'], 'com.cli');
    expect(masonService.vars['state_management'], 'riverpod');
    expect(masonService.vars['backend'], 'rest_firebase_hybrid');
    expect(masonService.vars['auth'], isFalse);
    expect(masonService.vars['offline_support'], isFalse);
  });

  test('starter brick supports all state/backend/auth/offline combinations',
      () async {
    final repoRoot = previousDirectory.parent.path;
    final masonService = MasonService(
      logger: Logger(),
      workingDirectory: Directory(repoRoot),
    );

    for (final stateManagement in ['riverpod', 'bloc']) {
      for (final backend in ['rest_firebase_hybrid', 'firebase']) {
        for (final includeAuth in [true, false]) {
          for (final includeOffline in [true, false]) {
            final outputDirectory = Directory(
              p.join(
                tempDirectory.path,
                [
                  stateManagement,
                  backend,
                  includeAuth ? 'auth' : 'no_auth',
                  includeOffline ? 'offline' : 'online',
                ].join('_'),
              ),
            );

            await masonService.generate(
              brickName: 'starter',
              targetDirectory: outputDirectory.path,
              force: true,
              vars: {
                'app_name': 'sample_app',
                'org_name': 'com.example',
                'state_management': stateManagement,
                'backend': backend,
                'auth': includeAuth,
                'offline_support': includeOffline,
              },
            );

            final files = _generatedFiles(outputDirectory);
            final pubspec = File(p.join(outputDirectory.path, 'pubspec.yaml'))
                .readAsStringSync();
            final router =
                File(p.join(outputDirectory.path, 'lib/app/router.dart'))
                    .readAsStringSync();

            expect(
              files.any((file) => file.path.contains('{{')),
              isFalse,
              reason: 'Raw mustache marker found in generated file path.',
            );
            expect(
              files.any((file) => file.readAsStringSync().contains('{{')),
              isFalse,
              reason: 'Raw mustache marker found in generated file content.',
            );

            expect(
              Directory(p.join(outputDirectory.path, 'lib/features/auth'))
                  .existsSync(),
              includeAuth,
            );
            expect(router.contains('RoutePaths.signIn'), includeAuth);
            expect(router.contains('SignInView'), includeAuth);

            if (backend == 'firebase') {
              expect(pubspec.contains('firebase_auth:'), includeAuth);
            }

            if (backend == 'rest_firebase_hybrid') {
              expect(pubspec.contains('connectivity_plus:'), includeOffline);
              expect(
                Directory(p.join(outputDirectory.path, 'lib/core/offline'))
                    .existsSync(),
                includeOffline,
              );
            }
          }
        }
      }
    }
  });

  test('normalizes firebase backend config values', () {
    expect(normalizeBackendPreset('Firebase'), 'firebase');
    expect(normalizeBackendPreset('firebase'), 'firebase');
    expect(
      normalizeBackendPreset('REST + Firebase hybrid'),
      'rest_firebase_hybrid',
    );
    expect(normalizeBackendPreset(null), 'rest_firebase_hybrid');
  });

  test('doctor firebase checks pass when tooling is available', () async {
    _createFlutterFactoryRoot();
    final exitCode = await _runDoctorWith({
      'dart --version': _success('Dart SDK version: 3.11.5'),
      'flutter --version': _success('Flutter 3.41.9'),
      'mason --version': _success('mason_cli 0.1.3'),
      'node --version': _success('v20.0.0'),
      'npm --version': _success('10.0.0'),
      'firebase --version': _success('15.0.0'),
      'flutterfire --version': _success('1.3.2'),
      'firebase login:list': _success('Logged in as user@example.com'),
    });

    expect(exitCode, 0);
  });

  test('doctor firebase fails when firebase CLI is missing', () async {
    _createFlutterFactoryRoot();
    final exitCode = await _runDoctorWith({
      'dart --version': _success('Dart SDK version: 3.11.5'),
      'flutter --version': _success('Flutter 3.41.9'),
      'mason --version': _success('mason_cli 0.1.3'),
      'node --version': _success('v20.0.0'),
      'npm --version': _success('10.0.0'),
      'flutterfire --version': _success('1.3.2'),
    });

    expect(exitCode, 70);
  });

  test('doctor firebase fails when flutterfire CLI is missing', () async {
    _createFlutterFactoryRoot();
    final exitCode = await _runDoctorWith({
      'dart --version': _success('Dart SDK version: 3.11.5'),
      'flutter --version': _success('Flutter 3.41.9'),
      'mason --version': _success('mason_cli 0.1.3'),
      'node --version': _success('v20.0.0'),
      'npm --version': _success('10.0.0'),
      'firebase --version': _success('15.0.0'),
      'dart pub global list': _success('mason_cli 0.1.3'),
    });

    expect(exitCode, 70);
  });

  test('doctor firebase fails when node is too old', () async {
    _createFlutterFactoryRoot();
    final exitCode = await _runDoctorWith({
      'dart --version': _success('Dart SDK version: 3.11.5'),
      'flutter --version': _success('Flutter 3.41.9'),
      'mason --version': _success('mason_cli 0.1.3'),
      'node --version': _success('v16.20.0'),
      'npm --version': _success('10.0.0'),
      'firebase --version': _success('15.0.0'),
      'flutterfire --version': _success('1.3.2'),
    });

    expect(exitCode, 70);
  });
}

Future<int> _runDoctorWith(Map<String, ProcessResult> results) {
  final runner = CommandRunner<int>('test', 'test')
    ..addCommand(
      DoctorCommand(
        logger: Logger(),
        processRunner: (executable, args) async {
          final key = '$executable ${args.join(' ')}';
          final result = results[key];
          if (result == null) {
            throw ProcessException(executable, args, 'not found');
          }

          return result;
        },
      ),
    );

  return runner.run(['doctor', '--firebase']).then((value) => value ?? 0);
}

ProcessResult _success(String stdout) {
  return ProcessResult(42, 0, stdout, '');
}

void _createFlutterFactoryRoot() {
  File('mason.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync('bricks: {}\n');
  for (final path in [
    'starter/brick.yaml',
    'bricks/feature/brick.yaml',
    'bricks/api_service/brick.yaml',
    'bricks/page/brick.yaml',
  ]) {
    File(path)
      ..createSync(recursive: true)
      ..writeAsStringSync('name: test\n');
  }
}

void _createGeneratedRouterFiles() {
  File('lib/core/router/route_paths.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
abstract final class RoutePaths {
  static const home = '/home';
  static const settings = '/settings';
  // flutter_factory: route-paths-start
  // flutter_factory: route-paths-end
}

abstract final class RouteNames {
  static const home = 'home';
  static const settings = 'settings';
  // flutter_factory: route-names-start
  // flutter_factory: route-names-end
}
''');

  File('lib/app/router.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('''
import '../features/home/presentation/views/home_view.dart';
import '../features/settings/presentation/views/settings_view.dart';
// flutter_factory: route-imports-start
// flutter_factory: route-imports-end

final routes = [
  HomeRoute.route(),
  SettingsRoute.route(),
  // flutter_factory: shell-routes-start
  // flutter_factory: shell-routes-end
];
''');
}

class _RecordingMasonService extends MasonService {
  _RecordingMasonService() : super(logger: Logger());

  late String brickName;
  late Map<String, dynamic> vars;
  String? targetDirectory;
  late bool force;

  @override
  Future<void> generate({
    required String brickName,
    required Map<String, dynamic> vars,
    String? targetDirectory,
    bool force = false,
  }) async {
    this.brickName = brickName;
    this.vars = Map<String, dynamic>.of(vars);
    this.targetDirectory = targetDirectory;
    this.force = force;
  }
}

List<File> _generatedFiles(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => !p.basename(file.path).endsWith('.lock'))
      .toList();
}

int _countOccurrences(String content, String pattern) {
  return pattern.allMatches(content).length;
}
