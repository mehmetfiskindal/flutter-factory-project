import 'package:flutter/material.dart';

class {{name.pascalCase()}} extends StatelessWidget {
  const {{name.pascalCase()}}({
    super.key,
    this.title = '{{name.titleCase()}}',
    this.onPressed,
  });

  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: onPressed == null ? null : const Icon(Icons.chevron_right),
        onTap: onPressed,
      ),
    );
  }
}
