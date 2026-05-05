import 'package:args/command_runner.dart';
import 'package:cli_dialog/cli_dialog.dart';
import 'package:mason_logger/mason_logger.dart';

import '../config/flutter_factory_config.dart';

class ConfigCommand extends Command<int> {
  ConfigCommand({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  @override
  String get description => 'Run interactive flutter_factory setup.';

  @override
  String get name => 'config';

  @override
  Future<int> run() async {
    _logger.info('Configuring flutter_factory defaults...');

    final dialog = CLI_Dialog(
      listQuestions: const [
        [
          {
            'question': 'State management?',
            'options': ['Riverpod', 'Bloc'],
          },
          'state_management',
        ],
        [
          {
            'question': 'Backend?',
            'options': ['REST + Firebase hybrid'],
          },
          'backend',
        ],
      ],
      questions: const [
        ['Organization id?', 'organization'],
      ],
      booleanQuestions: const [
        ['Auth ready?', 'auth'],
        ['Offline support?', 'offline_support'],
      ],
      order: const [
        'state_management',
        'backend',
        'organization',
        'auth',
        'offline_support',
      ],
    );

    final answers = dialog.ask();
    final config = FlutterFactoryConfig(
      stateManagement: _normalizeStateManagement(
        answers['state_management'] as String?,
      ),
      backend: _normalizeBackend(answers['backend'] as String?),
      organization: _normalizeOrganization(answers['organization'] as String?),
      auth: answers['auth'] as bool? ?? false,
      offline: answers['offline_support'] as bool? ?? false,
    );

    config.save();

    _logger.success('Saved ${FlutterFactoryConfig.fileName}.');
    return ExitCode.success.code;
  }

  String _normalizeStateManagement(String? value) {
    return switch (value) {
      'Bloc' => 'bloc',
      _ => 'riverpod',
    };
  }

  String _normalizeBackend(String? value) {
    return switch (value) {
      'REST + Firebase hybrid' => 'rest_firebase_hybrid',
      _ => 'rest_firebase_hybrid',
    };
  }

  String _normalizeOrganization(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'com.example';
    }

    return trimmed;
  }
}
