import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/add_command.dart';
import 'commands/config_command.dart';
import 'commands/create_command.dart';
import 'commands/doctor_command.dart';
import 'commands/verify_command.dart';
import 'generator/mason_service.dart';

class FlutterFactoryCommandRunner extends CommandRunner<int> {
  FlutterFactoryCommandRunner({
    required Logger logger,
    MasonService? masonService,
  })  : _logger = logger,
        super(
          'flutter_factory',
          'Generate production-ready Flutter apps in seconds.',
        ) {
    final generator = masonService ?? MasonService(logger: logger);

    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the current flutter_factory version.',
    );

    addCommand(CreateCommand(logger: logger, masonService: generator));
    addCommand(AddCommand(logger: logger, masonService: generator));
    addCommand(ConfigCommand(logger: logger));
    addCommand(DoctorCommand(logger: logger));
    addCommand(VerifyCommand(logger: logger, masonService: generator));
  }

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final results = parse(args);

      if (results['version'] == true) {
        _logger.info('flutter_factory 0.1.0');
        return ExitCode.success.code;
      }

      return await runCommand(results) ?? ExitCode.success.code;
    } on UsageException catch (error) {
      _logger.err(error.message);
      _logger.info('');
      _logger.info(error.usage);
      return ExitCode.usage.code;
    } on BrickNotFoundException catch (error) {
      _logger.err(error.message);
      return ExitCode.software.code;
    } on Object catch (error) {
      _logger.err(error.toString());
      return ExitCode.software.code;
    }
  }
}
