import 'dart:io';

import 'package:flutter_factory/flutter_factory.dart';
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

  test('doctor command is available', () async {
    final exitCode = await runFlutterFactory(['doctor']);

    expect(exitCode, anyOf(0, 70));
  });
}
