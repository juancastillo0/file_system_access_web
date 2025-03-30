import 'package:meta/meta.dart';

@immutable
abstract class Result<OK, ERR> {
  const Result._();

  const factory Result.ok(
    OK value,
  ) = Ok;
  factory Result.err(
    ERR value, {
    StackTrace stackTrace,
  }) = Err;

  OK? get okOrNull => when(ok: (ok) => ok, err: (_) => null);
  ERR? get errOrNull => when(ok: (ok) => null, err: (err) => err);

  OK unwrap() => map(
        ok: (ok) => ok.value,
        err: (err) => throw err,
      );

  T? whenOk<T>(T Function(OK) func) {
    return when(
      ok: (ok) => func(ok),
      err: (err) => null,
    );
  }

  T? whenErr<T>(T Function(ERR) func) {
    return when(
      ok: (ok) => null,
      err: (err) => func(err),
    );
  }

  T when<T>({
    required T Function(OK value) ok,
    required T Function(ERR value) err,
  }) {
    final v = this;
    if (v is Ok<OK, ERR>) {
      return ok(v.value);
    } else if (v is Err<OK, ERR>) {
      return err(v.error);
    }
    throw Exception();
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function(OK value)? ok,
    T Function(ERR value)? err,
  }) {
    final v = this;
    if (v is Ok<OK, ERR>) {
      return ok != null ? ok(v.value) : orElse.call();
    } else if (v is Err<OK, ERR>) {
      return err != null ? err(v.error) : orElse.call();
    }
    throw Exception();
  }

  T map<T>({
    required T Function(Ok<OK, ERR> value) ok,
    required T Function(Err<OK, ERR> value) err,
  }) {
    final v = this;
    if (v is Ok<OK, ERR>) {
      return ok(v);
    } else if (v is Err<OK, ERR>) {
      return err(v);
    }
    throw Exception();
  }

  T maybeMap<T>({
    required T Function() orElse,
    T Function(Ok<OK, ERR> value)? ok,
    T Function(Err<OK, ERR> value)? err,
  }) {
    final v = this;
    if (v is Ok<OK, ERR>) {
      return ok != null ? ok(v) : orElse.call();
    } else if (v is Err<OK, ERR>) {
      return err != null ? err(v) : orElse.call();
    }
    throw Exception();
  }

  bool get isOk => this is Ok;
  bool get isErr => this is Err;

  TypeResult get typeEnum;

  Result<T, ERR> mapOk<T>(T Function(OK) mapper) {
    return map(
      ok: (v) => Result.ok(mapper(v.value)),
      err: (v) => Result.err(v.error),
    );
  }

  Result<OK, T> mapErr<T>(T Function(ERR) mapper) {
    return map(
      ok: (v) => Result.ok(v.value),
      err: (v) => Result.err(mapper(v.error)),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Result<OK, ERR> &&
        other.runtimeType == runtimeType &&
        other.errOrNull == errOrNull &&
        other.okOrNull == okOrNull;
  }

  @override
  int get hashCode => Object.hash(runtimeType, errOrNull, okOrNull);

  @override
  String toString() {
    return map(
      ok: (ok) => 'Ok<$OK, $ERR>(${ok.value})',
      err: (err) =>
          'Err<$OK, $ERR>(${err.error}, stackTrace: ${err.stackTrace})',
    );
  }
}

enum TypeResult {
  ok,
  err,
}

TypeResult? parseTypeResult(String rawString, {bool caseSensitive = true}) {
  final _rawString = caseSensitive ? rawString : rawString.toLowerCase();
  for (final variant in TypeResult.values) {
    final variantString = caseSensitive
        ? variant.toEnumString()
        : variant.toEnumString().toLowerCase();
    if (_rawString == variantString) {
      return variant;
    }
  }
  return null;
}

extension TypeResultExtension on TypeResult {
  String toEnumString() => toString().split('.')[1];
  String enumType() => toString().split('.')[0];

  bool get isOk => this == TypeResult.ok;
  bool get isErr => this == TypeResult.err;

  T when<T>({
    required T Function() ok,
    required T Function() err,
  }) {
    switch (this) {
      case TypeResult.ok:
        return ok();
      case TypeResult.err:
        return err();
    }
  }

  T maybeWhen<T>({
    T Function()? ok,
    T Function()? err,
    required T Function() orElse,
  }) {
    T Function()? c;
    switch (this) {
      case TypeResult.ok:
        c = ok;
        break;
      case TypeResult.err:
        c = err;
        break;
    }
    return (c ?? orElse).call();
  }
}

class Ok<OK, ERR> extends Result<OK, ERR> {
  final OK value;

  const Ok(
    this.value,
  ) : super._();

  @override
  TypeResult get typeEnum => TypeResult.ok;
}

class Err<OK, ERR> extends Result<OK, ERR> {
  final ERR error;
  final StackTrace stackTrace;

  Err(
    this.error, {
    StackTrace? stackTrace,
  })  : stackTrace = stackTrace ?? StackTrace.current,
        super._();

  @override
  TypeResult get typeEnum => TypeResult.err;
}
