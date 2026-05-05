import 'package:flutter_riverpod/flutter_riverpod.dart';

final {{name.camelCase()}}ControllerProvider =
    AsyncNotifierProvider<{{name.pascalCase()}}Controller, String>(
  {{name.pascalCase()}}Controller.new,
);

class {{name.pascalCase()}}Controller extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return '{{name.titleCase()}} ready';
  }
}
