import 'package:flutter/material.dart';
{{#is_firebase_backend}}import 'package:firebase_core/firebase_core.dart';
{{/is_firebase_backend}}
{{#is_riverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{/is_riverpod}}{{#is_bloc}}import 'package:flutter_bloc/flutter_bloc.dart';
{{/is_bloc}}

import 'app/app.dart';
import 'app/di.dart';
import 'app/flavor.dart';
{{#is_firebase_backend}}import 'firebase_options.dart';
{{/is_firebase_backend}}
{{#is_bloc}}import 'features/auth/presentation/controllers/auth_bloc.dart';
{{/is_bloc}}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = AppEnvironment.fromFlavor(AppFlavor.current);
  {{#is_firebase_backend}}await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  {{/is_firebase_backend}}
  final dependencies = await configureDependencies(environment);

  runApp(
    {{#is_riverpod}}
    UncontrolledProviderScope(
      container: dependencies,
      child: const {{app_name.pascalCase()}}Application(),
    ),
    {{/is_riverpod}}{{#is_bloc}}
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: dependencies.environment),
        RepositoryProvider.value(value: dependencies.authRepository),
        RepositoryProvider.value(value: dependencies.getCurrentUserUseCase),
        RepositoryProvider.value(value: dependencies.signInUseCase),
        RepositoryProvider.value(value: dependencies.signOutUseCase),
        {{#is_firebase_backend}}
        RepositoryProvider.value(value: dependencies.firebaseAuth),
        RepositoryProvider.value(value: dependencies.firestore),
        RepositoryProvider.value(value: dependencies.storage),
        RepositoryProvider.value(value: dependencies.firestoreService),
        RepositoryProvider.value(value: dependencies.cloudStorageService),
        {{/is_firebase_backend}}
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          getCurrentUserUseCase: dependencies.getCurrentUserUseCase,
          signInUseCase: dependencies.signInUseCase,
          signOutUseCase: dependencies.signOutUseCase,
        )..add(const AuthStarted()),
        child: const {{app_name.pascalCase()}}Application(),
      ),
    ),
    {{/is_bloc}}
  );
}
