import 'dart:io';

import 'package:path/path.dart' as p;

class RouteIntegrationResult {
  const RouteIntegrationResult({
    required this.updatedFiles,
    required this.skippedReason,
  });

  final List<String> updatedFiles;
  final String? skippedReason;

  bool get didUpdate => updatedFiles.isNotEmpty;
}

class RouteIntegrator {
  RouteIntegrator({
    Directory? workingDirectory,
  }) : _workingDirectory = workingDirectory ?? Directory.current;

  final Directory _workingDirectory;

  RouteIntegrationResult addPageRoute({
    required String pageName,
    required String featureName,
    String? routePath,
  }) {
    final routePathsFile = File(
      p.join(
          _workingDirectory.path, 'lib', 'core', 'router', 'route_paths.dart'),
    );
    final routerFile = File(
      p.join(_workingDirectory.path, 'lib', 'app', 'router.dart'),
    );

    if (!routePathsFile.existsSync() || !routerFile.existsSync()) {
      return const RouteIntegrationResult(
        updatedFiles: [],
        skippedReason:
            'Route auto-wire skipped because lib/core/router/route_paths.dart or lib/app/router.dart was not found.',
      );
    }

    final routePathsUpdated = _updateRoutePaths(
      file: routePathsFile,
      pageName: pageName,
      routePath: routePath,
    );
    final routerUpdated = _updateRouter(
      file: routerFile,
      pageName: pageName,
      featureName: featureName,
    );

    final updatedFiles = [
      if (routePathsUpdated)
        p.relative(routePathsFile.path, from: _workingDirectory.path),
      if (routerUpdated)
        p.relative(routerFile.path, from: _workingDirectory.path),
    ];

    if (updatedFiles.isEmpty) {
      return const RouteIntegrationResult(
        updatedFiles: [],
        skippedReason:
            'Route auto-wire skipped because flutter_factory route markers were not found or the route already exists.',
      );
    }

    return RouteIntegrationResult(
      updatedFiles: updatedFiles,
      skippedReason: null,
    );
  }

  bool _updateRoutePaths({
    required File file,
    required String pageName,
    String? routePath,
  }) {
    final content = file.readAsStringSync();
    final routeField = _camelCase(pageName);
    final pathEntry = "  static const $routeField = "
        "'${routePath ?? '/${_paramCase(pageName)}'}';";
    final nameEntry = "  static const $routeField = '$routeField';";

    var updated = content;
    updated = _insertBeforeMarker(
      content: updated,
      marker: 'flutter_factory: route-paths-end',
      line: pathEntry,
    );
    updated = _insertBeforeMarker(
      content: updated,
      marker: 'flutter_factory: route-names-end',
      line: nameEntry,
    );

    if (updated == content) {
      return false;
    }

    file.writeAsStringSync(updated);
    return true;
  }

  bool _updateRouter({
    required File file,
    required String pageName,
    required String featureName,
  }) {
    final content = file.readAsStringSync();
    final routeClass = '${_pascalCase(pageName)}Route';
    final importEntry =
        "import '../features/${_snakeCase(featureName)}/presentation/routes/${_snakeCase(pageName)}_route.dart';";
    final routeEntry = '          $routeClass.route(),';

    var updated = content;
    updated = _insertBeforeMarker(
      content: updated,
      marker: '// flutter_factory: route-imports-end',
      line: importEntry,
    );
    updated = _insertBeforeMarker(
      content: updated,
      marker: 'flutter_factory: shell-routes-end',
      line: routeEntry,
    );

    if (updated == content) {
      return false;
    }

    file.writeAsStringSync(updated);
    return true;
  }

  String _insertBeforeMarker({
    required String content,
    required String marker,
    required String line,
  }) {
    if (content.contains(line)) {
      return content;
    }

    final lines = content.split('\n');
    final markerIndex =
        lines.indexWhere((candidate) => candidate.contains(marker));
    if (markerIndex == -1) {
      return content;
    }

    lines.insert(markerIndex, line);
    return lines.join('\n');
  }

  String _snakeCase(String value) {
    return value.trim().toLowerCase();
  }

  String _paramCase(String value) {
    return _snakeCase(value).replaceAll('_', '-');
  }

  String _camelCase(String value) {
    final parts = _snakeCase(value).split('_');
    return [
      parts.first,
      for (final part in parts.skip(1)) _capitalize(part),
    ].join();
  }

  String _pascalCase(String value) {
    return _snakeCase(value).split('_').map(_capitalize).join();
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
