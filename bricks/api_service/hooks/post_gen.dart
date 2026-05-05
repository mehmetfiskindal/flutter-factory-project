import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  if (context.vars['run_codegen'] == false) {
    context.logger.info(
      'Skipped code generation. Run dart run build_runner build later.',
    );
    return;
  }

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    return;
  }

  final pubspecContent = pubspec.readAsStringSync();
  final hasBuildRunner = pubspecContent.contains('build_runner:');
  final hasFreezed = pubspecContent.contains('freezed:');
  final hasJsonSerializable = pubspecContent.contains('json_serializable:');

  if (!hasBuildRunner || !hasFreezed || !hasJsonSerializable) {
    context.logger.warn(
      'Skipped Freezed code generation. Add build_runner, freezed, '
      'json_serializable, freezed_annotation, and json_annotation to pubspec.yaml.',
    );
    return;
  }

  final progress = context.logger.progress('Running build_runner');
  final result = await Process.run(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    runInShell: true,
  );

  if (result.exitCode != 0) {
    progress.fail('build_runner failed');
    context.logger.warn(result.stderr.toString());
    return;
  }

  progress.complete('Generated Freezed and JSON files');
}
