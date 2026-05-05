class {{name.pascalCase()}}Entity {
  const {{name.pascalCase()}}Entity({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}
