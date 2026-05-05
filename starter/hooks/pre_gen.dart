import 'package:mason/mason.dart';

void run(HookContext context) {
  final stateManagement = (context.vars['state_management'] as String?)
      ?.trim()
      .toLowerCase();
  final isBloc = stateManagement == 'bloc';
  final normalizedStateManagement = isBloc ? 'bloc' : 'riverpod';
  final backend = (context.vars['backend'] as String?)?.trim().toLowerCase();
  final isFirebaseBackend = backend == 'firebase';
  final normalizedBackend = isFirebaseBackend
      ? 'firebase'
      : 'rest_firebase_hybrid';

  context.vars = {
    ...context.vars,
    'state_management': normalizedStateManagement,
    'backend': normalizedBackend,
    'is_riverpod': normalizedStateManagement == 'riverpod',
    'is_bloc': normalizedStateManagement == 'bloc',
    'is_rest_backend': normalizedBackend == 'rest_firebase_hybrid',
    'is_firebase_backend': normalizedBackend == 'firebase',
    'state_folder': normalizedStateManagement == 'bloc'
        ? 'controllers'
        : 'providers',
  };
}
