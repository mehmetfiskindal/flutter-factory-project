import '../error/failure.dart';

sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(T data) = ApiSuccess<T>;

  const factory ApiResult.failure(Failure failure) = ApiFailure<T>;

  bool get isSuccess => this is ApiSuccess<T>;

  bool get isFailure => this is ApiFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(failure: final value) => failure(value),
    };
  }

  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T data) onSuccess,
  ) {
    return when(
      success: onSuccess,
      failure: onFailure,
    );
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.failure);

  final Failure failure;
}
