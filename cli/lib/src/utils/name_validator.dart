import 'package:args/command_runner.dart';

final _dartIdentifierPattern = RegExp(r'^[a-z][a-z0-9_]*$');

void validateDartIdentifier(String value, {required String label}) {
  if (_dartIdentifierPattern.hasMatch(value)) {
    return;
  }

  throw UsageException(
    'Invalid <$label> "$value". Use snake_case, start with a lowercase letter, '
        'and include only lowercase letters, numbers, and underscores.',
    '',
  );
}

final _reverseDomainPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$');

void validateReverseDomain(String value, {required String label}) {
  if (_reverseDomainPattern.hasMatch(value)) {
    return;
  }

  throw UsageException(
    'Invalid <$label> "$value". Use a reverse-domain identifier like '
        'com.fiskindal.',
    '',
  );
}
