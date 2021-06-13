import 'package:file_system_access/src/utils.dart';

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
