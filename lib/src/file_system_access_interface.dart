import 'dart:async';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as file_selector;

import 'package:file_system_access/src/models/errors.dart';
import 'package:file_system_access/src/models/params.dart';
import 'package:file_system_access/src/models/result.dart';
import 'package:file_system_access/src/models/serialized_entity.dart';
import 'package:file_system_access/src/models/sync.dart';
import 'package:file_system_access/src/models/write_chunk_type.dart';

export 'package:file_selector/file_selector.dart' show XFile;
export 'package:file_system_access/src/models/params.dart';

/// If the state of the read permission of this handle is anything
/// other than "prompt", this will return that state directly.
/// If it is "prompt" however, user activation is needed and
/// this will show a confirmation prompt to the user.
/// The new read permission state is then returned,
/// depending on the user’s response to the prompt.
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

  Future<void> remove({
    bool? recursive,
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
/// [description] An optional description of the category of files types allowed
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
  Future<file_selector.XFile> getFile();

  /// throws NotAllowedError if
  /// FileSystemPermissionMode.readwrite is not granted
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
  Future<Result<FileSystemFileHandle, BaseFileError>> getOrReplaceFileHandle(
    String name,
  ) {
    return _getOrReplaceEntityHandle(name, getFileHandle);
  }

  Future<Result<FileSystemDirectoryHandle, BaseFileError>>
      getOrReplaceDirectoryHandle(String name) {
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
  Future<List<FileSystemFileHandle>> showOpenFilePicker([
    FsOpenOptions options = const FsOpenOptions(),
  ]);

  /// https://developer.mozilla.org/docs/Web/API/Window/showOpenFilePicker
  /// Exception AbortError
  Future<FileSystemFileHandle?> showOpenSingleFilePicker([
    FsOpenOptions options = const FsOpenOptions(),
  ]) async {
    final files = await showOpenFilePicker(
      options.copyWith(multiple: false),
    );
    return files.isEmpty ? null : files[0];
  }

  /// https://developer.mozilla.org/docs/Web/API/Window/showSaveFilePicker
  /// Exception AbortError
  Future<FileSystemFileHandle?> showSaveFilePicker([
    FsSaveOptions options = const FsSaveOptions(),
  ]);

  /// https://developer.mozilla.org/docs/Web/API/Window/showDirectoryPicker
  /// Exception AbortError
  Future<FileSystemDirectoryHandle?> showDirectoryPicker([
    FsDirectoryOptions options = const FsDirectoryOptions(),
  ]);

  /// Utility function for querying and requesting
  /// permission if it hasn't been granted
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

  Future<Result<DirectorySyncResult?, void>> copyDirectory(
    FileSystemDirectoryHandle handle,
    FileSystemDirectoryHandle newHandle,
  ) async {
    if (await handle.isSameEntry(newHandle)) {
      return const Ok(null);
    }
    final serDir = await SerializedDirectory.fromHandle(handle);

    final _synchronizer = DirectorySynchronizer(
      getSerializedEntities: () => serDir.entities,
    );
    final success = await _synchronizer.selectDirectory(newHandle);
    if (success) {
      final result = await _synchronizer.saveEntities();
      await _synchronizer.dispose();
      return Ok(result);
    } else {
      await _synchronizer.dispose();
      return Err(null);
    }
  }

  /// If [isSupported] is false, [showOpenFilePicker] will throw and exception.
  /// You can use this method for getting a list of selected files.
  Future<List<FileSystemFileWebSafe>> showOpenFilePickerWebSafe([
    FsOpenOptions options = const FsOpenOptions(),
  ]) async {
    if (isSupported) {
      final selection = await showOpenFilePicker(options);
      return Future.wait(selection.map(
        (e) async => FileSystemFileWebSafe(
          file: await e.getFile(),
          handle: e,
        ),
      ));
    }
    final files = await file_selector.openFiles(
      initialDirectory: options.startIn?.path,
      acceptedTypeGroups: options.types
          .map(
            (e) => file_selector.XTypeGroup(
              label: e.description,
              extensions: e.accept.values.expand((_e) => _e).toList(),
              // TODO: test mimeTypes and webWildCards
              mimeTypes: e.accept.keys.toList(),
              webWildCards: null,
            ),
          )
          .toList(),
    );
    return files.map((file) => FileSystemFileWebSafe(file: file)).toList();
  }

  /// Only available for the WEB platform.
  Future<FileSystemPersistance> getPersistance({
    String databaseName = 'FilesDB',
    String objectStoreName = 'FilesObjectStore',
  });

  /// Only available for the WEB platform.
  StorageManager get storageManager;
  /// Only available for Native platforms.
  FileSystemHandle? getIoNativeHandleFromPath(String path);
}

abstract class FileSystemPersistance {
  FileSystemPersistanceItem? get(int id);
  Future<FileSystemPersistanceItem?> delete(int id);
  Future<FileSystemPersistanceItem> put(
    FileSystemHandle handle,
    // TODO: { int? id, }
  );

  /// Useful when [FileSystem.isSupported] is false and therefore you
  /// do not have access to [FileSystemHandle]s or maybe you expect the user
  /// to delete the file referenced by the [FileSystemHandle] and you what to
  /// keep the file's information and [ByteBuffer] data persisted in IndexedDB.
  ///
  /// Probably used in conjunction with [FileSystem.showOpenFilePickerWebSafe].
  Future<FileSystemPersistanceItem> putFile(file_selector.XFile file);
  // Map<int, FileSystemPersistanceItem> get allMap;
  List<FileSystemPersistanceItem> getAll();
}

mixin FileSystemPersistanceItem {
  int get id;
  FileSystemHandle? get handle;
  PersistedFile? get persistedFile;
  DateTime get savedDate;

  T when<T>({
    required T Function(FileSystemHandle handle) handle,
    required T Function(PersistedFile persistedFile) persistedFile,
  }) {
    if (this.handle != null) {
      return handle(this.handle!);
    } else {
      return persistedFile(this.persistedFile!);
    }
  }
}

class PersistedFile {
  final String name;
  final String mimeType;
  final DateTime lastModified;
  final ByteBuffer arrayBuffer;
  final String digestSha1Hex;
  final String? webkitRelativePath;

  PersistedFile({
    required this.name,
    required this.mimeType,
    required this.lastModified,
    required this.arrayBuffer,
    required this.digestSha1Hex,
    this.webkitRelativePath,
  });

  late final file_selector.XFile file = file_selector.XFile.fromData(
    arrayBuffer.asUint8List(),
    lastModified: lastModified,
    length: arrayBuffer.lengthInBytes,
    mimeType: mimeType,
    name: name,
  );
}

class FileSystemFileWebSafe {
  final FileSystemFileHandle? handle;
  final file_selector.XFile file;

  FileSystemFileWebSafe({
    this.handle,
    required this.file,
  });
}

abstract class StorageEstimate {
  /// A numeric value in bytes approximating the amount of storage space
  /// currently being used by the site or Web app, out of the
  /// available space as indicated by quota. Unit is byte.
  int get usage;

  /// A numeric value in bytes which provides a conservative approximation
  /// of the total storage the user's device or computer has available for
  /// the site origin or Web app. It's possible that there's more than this
  /// amount of space available though you can't rely on that being the case.
  int get quota;

  /// Example: {indexedDB: 21160, serviceWorkerRegistrations: 328}
  Map<String, int> get usageDetails;
}

abstract class StorageManager {
  /// https://developer.mozilla.org/en-US/docs/Web/API/StorageManager/persisted
  Future<bool> persisted();

  /// https://developer.mozilla.org/en-US/docs/Web/API/StorageManager/persist
  Future<bool> persist();

  /// https://developer.mozilla.org/en-US/docs/Web/API/StorageManager/estimate
  Future<StorageEstimate> estimate();

  /// https://wicg.github.io/file-system-access/#dom-storagemanager-getdirectory
  /// throws SecurityError
  Future<FileSystemDirectoryHandle> getDirectory();
}
