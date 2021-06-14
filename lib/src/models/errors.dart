import 'package:file_system_access/src/utils.dart';

enum BaseFileErrorType {
  NotAllowedError,
  TypeError,
}

class BaseFileError {
  final BaseFileErrorType type;
  final Object? rawError;
  final StackTrace? rawStack;

  const BaseFileError({
    required this.type,
    this.rawError,
    this.rawStack,
  });

  static BaseFileErrorType? typeFromString(String raw) {
    return parseEnum(raw, BaseFileErrorType.values);
  }

  factory BaseFileError.castGetHandleError(GetHandleError err) {
    if (GetHandleErrorType.NotAllowedError != err.type &&
        err.type != GetHandleErrorType.TypeError) {
      throw err;
    }
    return BaseFileError(
      type: err.type == GetHandleErrorType.NotAllowedError
          ? BaseFileErrorType.NotAllowedError
          : BaseFileErrorType.TypeError,
      rawError: err.rawError,
      rawStack: err.rawStack,
    );
  }

  factory BaseFileError.castRemoveEntryError(RemoveEntryError err) {
    if (RemoveEntryErrorType.NotAllowedError != err.type &&
        err.type != RemoveEntryErrorType.TypeError) {
      throw err;
    }
    return BaseFileError(
      type: err.type == RemoveEntryErrorType.NotAllowedError
          ? BaseFileErrorType.NotAllowedError
          : BaseFileErrorType.TypeError,
      rawError: err.rawError,
      rawStack: err.rawStack,
    );
  }

  @override
  String toString() {
    return 'BaseFileError(type: $type, rawError: $rawError, rawStack: $rawStack)';
  }
}

/// https://developer.mozilla.org/en-US/docs/Web/API/FileSystemDirectoryHandle/getFileHandle
enum GetHandleErrorType {
  NotFoundError,
  NotAllowedError,
  TypeError,
  TypeMismatchError,
}

class GetHandleError {
  final GetHandleErrorType type;
  final Object? rawError;
  final StackTrace? rawStack;

  const GetHandleError({
    required this.type,
    this.rawError,
    this.rawStack,
  });

  static GetHandleErrorType? typeFromString(String raw) {
    return parseEnum(raw, GetHandleErrorType.values);
  }

  @override
  String toString() {
    return 'GetHandleError(type: $type, rawError: $rawError, rawStack: $rawStack)';
  }
}

/// https://developer.mozilla.org/en-US/docs/Web/API/FileSystemDirectoryHandle/removeEntry
enum RemoveEntryErrorType {
  NotFoundError,
  NotAllowedError,
  TypeError,
  InvalidModificationError,
}

class RemoveEntryError {
  final RemoveEntryErrorType type;
  final Object? rawError;
  final StackTrace? rawStack;

  const RemoveEntryError({
    required this.type,
    this.rawError,
    this.rawStack,
  });

  static RemoveEntryErrorType? typeFromString(String raw) {
    return parseEnum(raw, RemoveEntryErrorType.values);
  }

  @override
  String toString() {
    return 'RemoveEntryError(type: $type, rawError: $rawError, rawStack: $rawStack)';
  }
}

// class FileSystemErrorType {
//   final String name;
//   const FileSystemErrorType._(this.name);

//   static const NotFoundError = FileSystemErrorType._("NotFoundError");
//   static const NotAllowedError = FileSystemErrorType._("NotAllowedError");
//   static const TypeError = FileSystemErrorType._("TypeError");
//   static const TypeMismatchError = FileSystemErrorType._("TypeMismatchError");
//   static const InvalidModificationError =
//       FileSystemErrorType._("InvalidModificationError");

//   @override
//   bool operator ==(Object? other) {
//     return other is FileSystemErrorType && other.name == name;
//   }

//   @override
//   int get hashCode => name.hashCode;

//   @override
//   String toString() {
//     return name;
//   }

//   static const values = [
//     NotFoundError,
//     NotAllowedError,
//     TypeError,
//     TypeMismatchError,
//     InvalidModificationError,
//   ];

//   static FileSystemErrorType? fromString(String raw) {
//     for (final v in values) {
//       if (raw == v.name) {
//         return v;
//       }
//     }
//     return null;
//   }
// }
