sealed class AsyncValue<T> {
  const AsyncValue();

  bool get isLoading => this is AsyncLoading<T>;
  bool get hasError => this is AsyncError<T>;
  bool get hasValue => this is AsyncData<T>;

  T? get valueOrNull => switch (this) {
        AsyncData(:final value) => value,
        _ => null,
      };

  Object? get errorOrNull => switch (this) {
        AsyncError(:final error) => error,
        _ => null,
      };
}

class AsyncIdle<T> extends AsyncValue<T> {
  const AsyncIdle();
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);
  final T value;
}

class AsyncError<T> extends AsyncValue<T> {
  const AsyncError(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;
}
