import 'dart:io';

import 'package:yaml/yaml.dart';

class FlutterFactoryConfig {
  const FlutterFactoryConfig({
    this.stateManagement,
    this.backend,
    this.organization,
    this.auth = false,
    this.offline = false,
  });

  static const fileName = '.flutter_factory.yaml';

  final String? stateManagement;
  final String? backend;
  final String? organization;
  final bool auth;
  final bool offline;

  static FlutterFactoryConfig load({Directory? directory}) {
    final file = File(
      '${directory?.path ?? Directory.current.path}/$fileName',
    );

    if (!file.existsSync()) {
      return const FlutterFactoryConfig();
    }

    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) {
      return const FlutterFactoryConfig();
    }

    return FlutterFactoryConfig(
      stateManagement: document['state_management'] as String?,
      backend: document['backend'] as String?,
      organization: document['organization'] as String?,
      auth: document['auth'] as bool? ?? false,
      offline: document['offline_support'] as bool? ?? false,
    );
  }

  void save({Directory? directory}) {
    final file = File(
      '${directory?.path ?? Directory.current.path}/$fileName',
    );

    file.writeAsStringSync('''
state_management: ${stateManagement ?? 'riverpod'}
backend: ${backend ?? 'rest_firebase_hybrid'}
organization: ${organization ?? 'com.example'}
auth: $auth
offline_support: $offline
''');
  }
}
