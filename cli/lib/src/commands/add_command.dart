import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../config/flutter_factory_config.dart';
import '../generator/mason_service.dart';
import '../generator/route_integrator.dart';
import '../utils/name_validator.dart';

class AddCommand extends Command<int> {
  AddCommand({
    required Logger logger,
    required MasonService masonService,
  }) {
    addSubcommand(AddFeatureCommand(
      logger: logger,
      masonService: masonService,
    ));
    addSubcommand(AddApiCommand(
      logger: logger,
      masonService: masonService,
    ));
    addSubcommand(AddPageCommand(
      logger: logger,
      masonService: masonService,
    ));
    addSubcommand(AddUseCaseCommand(
      logger: logger,
      masonService: masonService,
    ));
    addSubcommand(AddWidgetCommand(
      logger: logger,
      masonService: masonService,
    ));
  }

  @override
  String get description =>
      'Add generated building blocks to a Flutter project.';

  @override
  String get name => 'add';
}

class AddFeatureCommand extends Command<int> {
  AddFeatureCommand({
    required Logger logger,
    required MasonService masonService,
  })  : _logger = logger,
        _masonService = masonService {
    argParser.addOption(
      'state',
      allowed: const ['riverpod', 'bloc'],
      help: 'State management solution for the generated feature.',
    );
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Overwrite generated files if they already exist.',
    );
  }

  final Logger _logger;
  final MasonService _masonService;

  @override
  String get description => 'Add a feature-first Clean Architecture module.';

  @override
  String get invocation =>
      'flutter_factory add feature <name> [--state riverpod|bloc] [--force]';

  @override
  String get name => 'feature';

  @override
  Future<int> run() async {
    final featureName = argResults?.rest.singleOrNull;
    if (featureName == null) {
      throw UsageException('Missing <name>.', usage);
    }

    validateDartIdentifier(featureName, label: 'name');
    final force = argResults?['force'] as bool? ?? false;
    ensureFeatureDoesNotExist(featureName, force: force);

    final config = FlutterFactoryConfig.load();
    final stateManagement =
        argResults?['state'] as String? ?? config.stateManagement ?? 'riverpod';

    _logger.info('Adding feature "$featureName"...');

    await _masonService.generate(
      brickName: 'feature',
      force: force,
      vars: {
        'name': featureName,
        'state_management': stateManagement,
      },
    );

    _logger.success('Feature "$featureName" generated.');
    return ExitCode.success.code;
  }
}

class AddApiCommand extends Command<int> {
  AddApiCommand({
    required Logger logger,
    required MasonService masonService,
  })  : _logger = logger,
        _masonService = masonService {
    argParser.addOption(
      'endpoint',
      help: 'REST endpoint. Defaults to /<name-param-case>.',
    );
    argParser
      ..addFlag(
        'force',
        negatable: false,
        help: 'Overwrite generated files if they already exist.',
      )
      ..addFlag(
        'codegen',
        defaultsTo: true,
        help: 'Run build_runner after generation.',
      );
  }

  final Logger _logger;
  final MasonService _masonService;

  @override
  String get description =>
      'Add API service, model, and repository scaffolding.';

  @override
  String get invocation =>
      'flutter_factory add api <name> [--endpoint <endpoint>] [--no-codegen] [--force]';

  @override
  String get name => 'api';

  @override
  Future<int> run() async {
    final apiName = argResults?.rest.singleOrNull;
    if (apiName == null) {
      throw UsageException('Missing <name>.', usage);
    }

    validateDartIdentifier(apiName, label: 'name');
    final force = argResults?['force'] as bool? ?? false;
    ensureFeatureDoesNotExist(apiName, force: force);

    final endpoint = argResults?['endpoint'] as String?;
    final codegen = argResults?['codegen'] as bool? ?? true;

    _logger.info('Adding API "$apiName"...');

    await _masonService.generate(
      brickName: 'api_service',
      force: force,
      vars: {
        'name': apiName,
        'run_codegen': codegen,
        if (endpoint != null) 'endpoint': endpoint,
      },
    );

    _logger.success('API "$apiName" generated.');
    return ExitCode.success.code;
  }
}

void ensureFeatureDoesNotExist(String featureName, {required bool force}) {
  final featureDirectory = Directory(
    p.join(Directory.current.path, 'lib', 'features', featureName),
  );

  if (!featureDirectory.existsSync() || force) {
    return;
  }

  throw UsageException(
    'Feature "$featureName" already exists at ${featureDirectory.path}. '
        'Choose another name or remove the existing feature first.',
    '',
  );
}

class AddPageCommand extends Command<int> {
  AddPageCommand({
    required Logger logger,
    required MasonService masonService,
  })  : _logger = logger,
        _masonService = masonService {
    argParser.addOption(
      'feature',
      mandatory: true,
      help: 'Target feature name.',
    );
    argParser
      ..addOption(
        'path',
        help: 'Route path. Defaults to /<name-param-case>.',
      )
      ..addFlag(
        'route',
        defaultsTo: true,
        help: 'Wire the page into the generated app router.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Overwrite generated files if they already exist.',
      );
  }

  final Logger _logger;
  final MasonService _masonService;

  @override
  String get description => 'Add a route-ready page inside a feature.';

  @override
  String get invocation =>
      'flutter_factory add page <name> --feature <feature_name> [--path /custom-path] [--no-route] [--force]';

  @override
  String get name => 'page';

  @override
  Future<int> run() async {
    final pageName = argResults?.rest.singleOrNull;
    if (pageName == null) {
      throw UsageException('Missing <name>.', usage);
    }

    validateDartIdentifier(pageName, label: 'name');

    final featureName = argResults?['feature'] as String;
    validateDartIdentifier(featureName, label: 'feature');
    final routePath = argResults?['path'] as String?;
    if (routePath != null) {
      validateRoutePath(routePath);
    }
    final force = argResults?['force'] as bool? ?? false;
    ensureFileDoesNotExist(
      p.join(
        'lib',
        'features',
        featureName,
        'presentation',
        'views',
        '${pageName}_view.dart',
      ),
      force: force,
    );

    _logger.info('Adding page "$pageName" to feature "$featureName"...');

    await _masonService.generate(
      brickName: 'page',
      force: force,
      vars: {
        'name': pageName,
        'feature': featureName,
        if (routePath != null) 'route_path': routePath,
      },
    );

    final shouldWireRoute = argResults?['route'] as bool? ?? true;
    if (shouldWireRoute) {
      final routeIntegration = RouteIntegrator().addPageRoute(
        pageName: pageName,
        featureName: featureName,
        routePath: routePath,
      );
      if (routeIntegration.didUpdate) {
        _logger.success(
          'Wired page route in ${routeIntegration.updatedFiles.join(', ')}.',
        );
      } else if (routeIntegration.skippedReason != null) {
        _logger.warn(routeIntegration.skippedReason!);
      }
    } else {
      _logger.info('Skipped route auto-wire.');
    }

    _logger.success('Page "$pageName" generated.');
    return ExitCode.success.code;
  }
}

class AddUseCaseCommand extends Command<int> {
  AddUseCaseCommand({
    required Logger logger,
    required MasonService masonService,
  })  : _logger = logger,
        _masonService = masonService {
    argParser
      ..addOption(
        'feature',
        mandatory: true,
        help: 'Target feature name.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Overwrite generated files if they already exist.',
      );
  }

  final Logger _logger;
  final MasonService _masonService;

  @override
  String get description => 'Add a domain use case inside a feature.';

  @override
  String get invocation =>
      'flutter_factory add usecase <name> --feature <feature_name> [--force]';

  @override
  String get name => 'usecase';

  @override
  Future<int> run() async {
    final useCaseName = argResults?.rest.singleOrNull;
    if (useCaseName == null) {
      throw UsageException('Missing <name>.', usage);
    }

    validateDartIdentifier(useCaseName, label: 'name');

    final featureName = argResults?['feature'] as String;
    validateDartIdentifier(featureName, label: 'feature');
    final force = argResults?['force'] as bool? ?? false;
    ensureFileDoesNotExist(
      p.join(
        'lib',
        'features',
        featureName,
        'domain',
        'usecases',
        '$useCaseName.dart',
      ),
      force: force,
    );

    _logger.info('Adding use case "$useCaseName" to feature "$featureName"...');

    await _masonService.generate(
      brickName: 'usecase',
      force: force,
      vars: {
        'name': useCaseName,
        'feature': featureName,
      },
    );

    _logger.success('Use case "$useCaseName" generated.');
    return ExitCode.success.code;
  }
}

class AddWidgetCommand extends Command<int> {
  AddWidgetCommand({
    required Logger logger,
    required MasonService masonService,
  })  : _logger = logger,
        _masonService = masonService {
    argParser
      ..addOption(
        'feature',
        mandatory: true,
        help: 'Target feature name.',
      )
      ..addFlag(
        'force',
        negatable: false,
        help: 'Overwrite generated files if they already exist.',
      );
  }

  final Logger _logger;
  final MasonService _masonService;

  @override
  String get description => 'Add a reusable widget inside a feature.';

  @override
  String get invocation =>
      'flutter_factory add widget <name> --feature <feature_name> [--force]';

  @override
  String get name => 'widget';

  @override
  Future<int> run() async {
    final widgetName = argResults?.rest.singleOrNull;
    if (widgetName == null) {
      throw UsageException('Missing <name>.', usage);
    }

    validateDartIdentifier(widgetName, label: 'name');

    final featureName = argResults?['feature'] as String;
    validateDartIdentifier(featureName, label: 'feature');
    final force = argResults?['force'] as bool? ?? false;
    ensureFileDoesNotExist(
      p.join(
        'lib',
        'features',
        featureName,
        'presentation',
        'widgets',
        '$widgetName.dart',
      ),
      force: force,
    );

    _logger.info('Adding widget "$widgetName" to feature "$featureName"...');

    await _masonService.generate(
      brickName: 'widget',
      force: force,
      vars: {
        'name': widgetName,
        'feature': featureName,
      },
    );

    _logger.success('Widget "$widgetName" generated.');
    return ExitCode.success.code;
  }
}

void ensureFileDoesNotExist(String relativePath, {required bool force}) {
  final file = File(p.join(Directory.current.path, relativePath));

  if (!file.existsSync() || force) {
    return;
  }

  throw UsageException(
    'File already exists at ${file.path}. Use --force to overwrite it.',
    '',
  );
}
