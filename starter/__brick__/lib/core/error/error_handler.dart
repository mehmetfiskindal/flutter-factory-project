{{#is_rest_backend}}
import 'package:dio/dio.dart';
{{/is_rest_backend}}{{#is_firebase_backend}}import 'package:firebase_core/firebase_core.dart';
{{/is_firebase_backend}}

import 'app_exception.dart';
import 'failure.dart';

abstract final class ErrorHandler {
  static AppException toException(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (error is AppException) {
      return error;
    }

    {{#is_rest_backend}}
    if (error is DioException) {
      return _fromDioException(error, stackTrace);
    }
    {{/is_rest_backend}}{{#is_firebase_backend}}
    if (error is FirebaseException) {
      return _fromFirebaseException(error, stackTrace);
    }
    {{/is_firebase_backend}}

    if (error is FormatException || error is ArgumentError) {
      return ValidationException(
        message: error.toString(),
        code: 'validation_error',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return UnknownAppException(
      message: 'Something went wrong.',
      code: 'unknown_error',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static Failure toFailure(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    return Failure.fromException(toException(error, stackTrace));
  }

  static String messageFor(Object error) {
    return toException(error).message;
  }

  {{#is_rest_backend}}
  static AppException _fromDioException(
    DioException error,
    StackTrace? stackTrace,
  ) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 401) {
      return UnauthorizedException(
        code: 'unauthorized',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (statusCode == 422) {
      return ValidationException(
        message: _serverMessage(error) ?? 'The submitted data is invalid.',
        code: 'validation_error',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (_isConnectionProblem(error)) {
      return NetworkException(
        message: 'Please check your internet connection.',
        code: 'network_error',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return NetworkException(
      message: _serverMessage(error) ?? 'Network request failed.',
      code: statusCode?.toString() ?? 'network_error',
      cause: error,
      stackTrace: stackTrace,
      statusCode: statusCode,
    );
  }

  static bool _isConnectionProblem(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }

  static String? _serverMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return error.response?.statusMessage;
  }
  {{/is_rest_backend}}{{#is_firebase_backend}}
  static AppException _fromFirebaseException(
    FirebaseException error,
    StackTrace? stackTrace,
  ) {
    final message = error.message ?? 'Firebase request failed.';

    return switch (error.code) {
      'permission-denied' || 'unauthenticated' => UnauthorizedException(
          message: message,
          code: error.code,
          cause: error,
          stackTrace: stackTrace,
        ),
      'invalid-email' ||
      'user-disabled' ||
      'user-not-found' ||
      'wrong-password' ||
      'weak-password' ||
      'email-already-in-use' =>
        ValidationException(
          message: message,
          code: error.code,
          cause: error,
          stackTrace: stackTrace,
        ),
      'network-request-failed' || 'unavailable' || 'deadline-exceeded' =>
        NetworkException(
          message: message,
          code: error.code,
          cause: error,
          stackTrace: stackTrace,
        ),
      _ => UnknownAppException(
          message: message,
          code: error.code,
          cause: error,
          stackTrace: stackTrace,
        ),
    };
  }
  {{/is_firebase_backend}}
}
