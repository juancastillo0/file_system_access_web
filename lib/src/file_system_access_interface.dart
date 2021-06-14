import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:file_system_access/src/models/result.dart';
import 'package:file_system_access/src/models/errors.dart';
import 'package:file_system_access/src/models/write_chunk_type.dart';

enum PermissionStateEnum { granted, denied, prompt }

/// https://developer.mozilla.org/docs/Web/API/FileSystemHandle
abstract class FileSystemHandle {
  Future<bool> isSameEntry(FileSystemHandle other);

  FileSystemHandleKind get kind;

  String get name;

  Future<PermissionStateEnum> queryPermission({
    FileSystemPermissionMode? mode,
  });

  Future<PermissionStateEnum> requestPermission({
    FileSystemPermissionMode? mode,
  });
}

/// https://developer.mozilla.org/docs/Web/API/window/showOpenFilePicker
/// {
///   description: 'Images',
///   accept: {
///     'image/*': ['.png', '.gif', '.jpeg', '.jpg']
///   }
/// }
///
/// [description] An optional description of the category of files types allowed.
/// [accept] An Object with the keys set to the MIME type and the
/// values an Array of file extensions.
class FilePickerAcceptType {
  const FilePickerAcceptType({this.description, required this.accept});
  final String? description;
  final Map<String, List<String> /*String | String[]*/ > accept;
}

enum FileSystemPermissionMode {
  read,
  readwrite,
}

enum FileSystemHandleKind { file, directory }

/// https://developer.mozilla.org/docs/Web/API/FileSystemWritableFileStream
abstract class FileSystemWritableFileStream {
  Future<void> write(FileSystemWriteChunkType data);

  Future<void> close();

  Future<void> seek(int position);

  Future<void> truncate(int size);
}

/// https://developer.mozilla.org/docs/Web/API/FileSystemFileHandle
abstract class FileSystemFileHandle extends FileSystemHandle {
  /// throws NotAllowedError if FileSystemPermissionMode.read is not granted
  Future<XFile> getFile();

  /// throws NotAllowedError if FileSystemPermissionMode.readwrite is not granted
  Future<FileSystemWritableFileStream> createWritable({bool? keepExistingData});
}

/// https://developer.mozilla.org/docs/Web/API/FileSystemDirectoryHandle
abstract class FileSystemDirectoryHandle extends FileSystemHandle {
  Future<Result<FileSystemFileHandle, GetHandleError>> getFileHandle(
    String name, {
    bool? create,
  });

  Future<Result<FileSystemDirectoryHandle, GetHandleError>> getDirectoryHandle(
    String name, {
    bool? create,
  });

  Future<Result<void, RemoveEntryError>> removeEntry(
    String name, {
    bool? recursive,
  });

  /// throws NotAllowedError if FileSystemPermissionMode.read is not granted
  Stream<FileSystemHandle> entries();

  Future<List<String>?> resolve(
    FileSystemHandle possibleDescendant,
  );
}

extension FileSystemDirectoryHandleExt on FileSystemDirectoryHandle {
  Future<Result<FileSystemFileHandle, BaseFileError>> getOrReplaceFileHandle<T>(
      String name) {
    return _getOrReplaceEntityHandle(name, getFileHandle);
  }

  Future<Result<FileSystemDirectoryHandle, BaseFileError>>
      getOrReplaceDirectoryHandle<T>(String name) {
    return _getOrReplaceEntityHandle(name, getDirectoryHandle);
  }

  Future<Result<T, BaseFileError>> _getOrReplaceEntityHandle<T>(
    String name,
    Future<Result<T, GetHandleError>> Function(String name, {bool? create})
        getHandle,
  ) async {
    final result = await getHandle(name, create: true);
    return result.map(
      ok: (ok) => Ok(ok.value),
      err: (err) async {
        final error = err.error;
        if (error.type == GetHandleErrorType.TypeMismatchError) {
          final removeResult = await removeEntry(name, recursive: true);
          return removeResult.when(
            ok: (_) {
              return getHandle(name, create: true).then(
                (value) => value.mapErr(
                  (err) => BaseFileError.castGetHandleError(err),
                ),
              );
            },
            err: (err) {
              switch (err.type) {
                case RemoveEntryErrorType.NotFoundError:
                  return getHandle(name, create: true).then(
                    (value) => value.mapErr(
                      (err) => BaseFileError.castGetHandleError(err),
                    ),
                  );
                case RemoveEntryErrorType.NotAllowedError:
                case RemoveEntryErrorType.TypeError:
                  return Err(BaseFileError.castRemoveEntryError(err));
                case RemoveEntryErrorType.InvalidModificationError:
                  throw Error();
              }
            },
          );
        } else {
          return Err(BaseFileError.castGetHandleError(err.error));
        }
      },
    );
  }
}

abstract class FileSystem extends FileSystemI {
  const FileSystem._();
  static FileSystem get instance => throw UnimplementedError();
}

abstract class FileSystemI {
  const FileSystemI();

  bool get isSupported;

  /// https://developer.mozilla.org/docs/Web/API/Window/showOpenFilePicker
  /// Exception AbortError
  Future<List<FileSystemFileHandle>> showOpenFilePicker({
    List<FilePickerAcceptType>? types,
    bool? excludeAcceptAllOption,
    bool? multiple,
  });

  /// https://developer.mozilla.org/docs/Web/API/Window/showOpenFilePicker
  /// Exception AbortError
  Future<FileSystemFileHandle?> showOpenSingleFilePicker({
    List<FilePickerAcceptType>? types,
    bool? excludeAcceptAllOption,
  }) async {
    final files = await showOpenFilePicker(
      multiple: false,
      excludeAcceptAllOption: excludeAcceptAllOption,
      types: types,
    );
    return files.isEmpty ? null : files[0];
  }

  /// https://developer.mozilla.org/docs/Web/API/Window/showSaveFilePicker
  /// Exception AbortError
  Future<FileSystemFileHandle?> showSaveFilePicker({
    List<FilePickerAcceptType>? types,
    bool? excludeAcceptAllOption,
  });

  /// https://developer.mozilla.org/docs/Web/API/Window/showDirectoryPicker
  /// Exception AbortError
  Future<FileSystemDirectoryHandle?> showDirectoryPicker();

  /// Utility function for querying and requesting permission if it hasn't been granted
  Future<bool> verifyPermission(
    FileSystemHandle fileHandle, {
    required FileSystemPermissionMode mode,
  }) async {
    // Check if permission was already granted. If so, return true.
    if (await fileHandle.queryPermission(mode: mode) ==
        PermissionStateEnum.granted) {
      return true;
    }
    // Request permission. If the user grants permission, return true.
    if (await fileHandle.requestPermission(mode: mode) ==
        PermissionStateEnum.granted) {
      return true;
    }
    // The user didn't grant permission, so return false.
    return false;
  }
}
