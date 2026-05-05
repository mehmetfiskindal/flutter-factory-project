import 'package:go_router/go_router.dart';

import '../views/{{name.snakeCase()}}_view.dart';

abstract final class {{name.pascalCase()}}Route {
  static const path = '/{{name.paramCase()}}';
  static const name = '{{name.camelCase()}}';

  static GoRoute route() {
    return GoRoute(
      path: path,
      name: name,
      builder: (context, state) => const {{name.pascalCase()}}View(),
    );
  }
}
