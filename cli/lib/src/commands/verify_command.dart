import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../generator/mason_service.dart';

typedef VerifyProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> args, {
  String? workingDirectory,
});

class VerifyCommand extends Command<int> {
  VerifyCommand({
    required Logger logger,
    required MasonService masonService,
    VerifyProcessRunner? processRunner,
    Directory Function()? tempDirectoryFactory,
  })  : _logger = logger,
        _masonService = masonService,
        _processRunner = processRunner ?? _defaultProcessRunner,
        _tempDirectoryFactory = tempDirectoryFactory ??
            (() => Directory.systemTemp
                .createTempSync('flutter_factory_verify_')) {
    argParser
      ..addFlag(
        'full',
        negatable: false,
        help: 'Verify all 16 state/backend/auth/offline starter combinations.',
      )
      ..addFlag(
        'analyze',
        defaultsTo: true,
        help: 'Run flutter pub get and flutter analyze for generated samples.',
      );
  }

  final Logger _logger;
  final MasonService _masonService;
  final VerifyProcessRunner _processRunner;
  final Directory Function() _tempDirectoryFactory;

  @override
  String get description =>
      'Verify starter generation locally without GitHub Actions.';

  @override
  String get invocation => 'flutter_factory verify [--full] [--no-analyze]';

  @override
  String get name => 'verify';

  @override
  Future<int> run() async {
    final full = argResults?['full'] as bool? ?? false;
    final analyze = argResults?['analyze'] as bool? ?? true;
    final outputRoot = _tempDirectoryFactory();
    final cases = full ? _fullCases : _sampleCases;

    _logger.info(
      'Verifying ${cases.length} starter combination(s) in ${outputRoot.path}...',
    );

    for (final testCase in cases) {
      final target = Directory(p.join(outputRoot.path, testCase.name));
      _logger.info('Generating ${testCase.name}...');
      await _masonService.generate(
        brickName: 'starter',
        targetDirectory: target.path,
        force: true,
        vars: {
          'app_name': 'sample_app',
          'org_name': 'com.example',
          'state_management': testCase.stateManagement,
          'backend': testCase.backend,
          'auth': testCase.auth,
          'offline_support': testCase.offline,
        },
      );

      _assertNoMustacheMarkers(target);

      if (analyze) {
        await _runChecked(
          'flutter',
          ['pub', 'get'],
          workingDirectory: target.path,
        );
        await _runChecked(
          'flutter',
          ['analyze'],
          workingDirectory: target.path,
        );
      }
    }

    _logger.success('Local verification passed.');
    return ExitCode.success.code;
  }

  void _assertNoMustacheMarkers(Directory directory) {
    final badPath = directory
        .listSync(recursive: true)
        .where((entity) => entity.path.contains('{{'))
        .firstOrNull;
    if (badPath != null) {
      throw StateError('Raw mustache marker found in ${badPath.path}.');
    }

    final badFile = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => !p.basename(file.path).endsWith('.lock'))
        .firstWhere(
          (file) => file.readAsStringSync().contains('{{'),
          orElse: () => File(''),
        );
    if (badFile.path.isNotEmpty) {
      throw StateError('Raw mustache marker found in ${badFile.path}.');
    }
  }

  Future<void> _runChecked(
    String executable,
    List<String> args, {
    required String workingDirectory,
  }) async {
    final result = await _processRunner(
      executable,
      args,
      workingDirectory: workingDirectory,
    );

    if (result.exitCode == ExitCode.success.code) {
      return;
    }

    throw ProcessException(
      executable,
      args,
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }

  static Future<ProcessResult> _defaultProcessRunner(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) {
    return Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
  }
}

class _StarterVerifyCase {
  const _StarterVerifyCase({
    required this.stateManagement,
    required this.backend,
    required this.auth,
    required this.offline,
  });

  final String stateManagement;
  final String backend;
  final bool auth;
  final bool offline;

  String get name {
    return [
      stateManagement,
      backend,
      auth ? 'auth' : 'no_auth',
      offline ? 'offline' : 'online',
    ].join('_');
  }
}

const _sampleCases = [
  _StarterVerifyCase(
    stateManagement: 'riverpod',
    backend: 'rest_firebase_hybrid',
    auth: true,
    offline: true,
  ),
  _StarterVerifyCase(
    stateManagement: 'bloc',
    backend: 'rest_firebase_hybrid',
    auth: false,
    offline: false,
  ),
  _StarterVerifyCase(
    stateManagement: 'riverpod',
    backend: 'firebase',
    auth: false,
    offline: false,
  ),
  _StarterVerifyCase(
    stateManagement: 'bloc',
    backend: 'firebase',
    auth: true,
    offline: false,
  ),
];

final _fullCases = <_StarterVerifyCase>[
  for (final stateManagement in ['riverpod', 'bloc'])
    for (final backend in ['rest_firebase_hybrid', 'firebase'])
      for (final auth in [true, false])
        for (final offline in [true, false])
          _StarterVerifyCase(
            stateManagement: stateManagement,
            backend: backend,
            auth: auth,
            offline: offline,
          ),
];
