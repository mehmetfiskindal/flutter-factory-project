import '../repositories/{{feature.snakeCase()}}_repository.dart';

class {{name.pascalCase()}}UseCase {
  const {{name.pascalCase()}}UseCase({
    required {{feature.pascalCase()}}Repository repository,
  }) : _repository = repository;

  final {{feature.pascalCase()}}Repository _repository;

  Future<void> call() async {
    await Future<void>.value();
    _repository.toString();
  }
}
