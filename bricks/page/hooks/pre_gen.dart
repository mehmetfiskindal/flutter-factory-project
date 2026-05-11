import 'package:mason/mason.dart';

void run(HookContext context) {
  final routePath = (context.vars['route_path'] as String?)?.trim();
  final name = context.vars['name'] as String;

  context.vars = {
    ...context.vars,
    'route_path': routePath == null || routePath.isEmpty
        ? '/${name.replaceAll('_', '-')}'
        : routePath,
  };
}
