import 'dart:async';

import 'package:file_system_access/src/file_system_access.dart';
import 'package:file_system_access/src/models/result.dart';
import 'package:file_system_access/src/models/serialized_entity.dart';
import 'package:flutter/foundation.dart';

enum SyncDirectoryErrorType {
  NotAllowedError,
}

class DirectorySyncronizer {
  FileSystemDirectoryHandle? _directoryHandle;
  FileSystemDirectoryHandle? get directoryHandle => _directoryHandle;

  final List<SerializedFileEntity> Function() getSerializedEntities;
  Duration? syncDuration;
  Timer? _timer;

  DirectorySyncronizer({
    required this.getSerializedEntities,
    this.syncDuration,
  }) {
    restartSync();
  }

  final _errorsController = StreamController<List<BaseFileError>>();
  Stream<List<BaseFileError>> get errors => _errorsController.stream;

  final Map<String, _SavedEntity> _savedFiles = {};

  void restartSync() {
    stopSync();
    if (syncDuration != null) {
      _timer = Timer.periodic(syncDuration!, (timer) async {
        if (directoryHandle != null) {
          await saveEntities();
        }
      });
    }
  }

  void stopSync() {
    _timer?.cancel();
  }

  void changeSyncDuration(Duration duration) {
    syncDuration = duration;
    if (isSynching) {
      restartSync();
    }
  }

  Map<String, SerializedFileEntity> savedEntities() {
    return _savedFiles.map((key, value) => MapEntry(key, value.value));
  }

  bool get isSynching => directoryHandle != null && (_timer?.isActive ?? false);

  bool isSynchedWithLocal() {
    final toSave = getSerializedEntities().asDirectoryMap();
    final saved = savedEntities();
    return mapEquals(
      saved,
      toSave,
    );
  }

  Future<bool> isSynchedWithFileSystem() async {
    if (directoryHandle == null) {
      return false;
    }
    final serDir = await SerializedDirectory.fromHandle(directoryHandle!);
    final saved = savedEntities();
    return mapEquals(
      saved,
      serDir.entities.asDirectoryMap(),
    );
  }

  Future<void> dispose() {
    stopSync();
    return _errorsController.close();
  }

  Future<Result<void, SyncDirectoryErrorType>> selectDirectory(
    FileSystemDirectoryHandle directory,
  ) async {
    final success = await FileSystem.instance.verifyPermission(
      directory,
      mode: FileSystemPermissionMode.readwrite,
    );

    if (!success) {
      return Err(SyncDirectoryErrorType.NotAllowedError);
    }
    if (directoryHandle != null) {
      if (await directoryHandle!.isSameEntry(directory)) {
        return Ok(null);
      } else {
        _savedFiles.clear();
      }
    }
    _directoryHandle = directory;
    _syncFuture = null;
    await saveEntities();
    return Ok(null);
  }

  Future<List<BaseFileError>>? _syncFuture;

  Future<List<BaseFileError>> saveEntities({
    bool forceUpdate = false,
  }) async {
    if (_syncFuture != null) {
      return _syncFuture!;
    }
    final _comp = Completer<List<BaseFileError>>();
    _syncFuture = _comp.future;
    final serialized = getSerializedEntities();

    final errors = await saveDirectoryEntities(
      directoryHandle!,
      serialized,
      _savedFiles,
      forceUpdate: forceUpdate,
    );

    if (_comp.future == _syncFuture) {
      _syncFuture = null;
      if (errors.isNotEmpty) {
        _errorsController.add(errors);
      }
    }
    _comp.complete(errors);
    return errors;
  }
}

Future<Result<FileSystemFileHandle, BaseFileError>> saveFile(
  FileSystemDirectoryHandle directory,
  SerializedFile serializedFile,
) async {
  final fileResult = await directory.getOrReplaceFileHandle(
    serializedFile.name,
  );

  return fileResult.map(
    ok: (ok) async {
      final file = ok.value;
      final writable = await file.createWritable();

      await writable.write(
        FileSystemWriteChunkType.string(serializedFile.content),
      );
      await writable.close();

      return ok;
    },
    err: (err) => err,
  );
}

Future<List<BaseFileError>> saveDirectoryEntities(
  FileSystemDirectoryHandle directory,
  List<SerializedFileEntity> serialized,
  Map<String, _SavedEntity> savedFiles, {
  bool forceUpdate = false,
}) async {
  final toSave = serialized.asDirectoryMap();

  final _futs = toSave.entries.map<Future<List<BaseFileError>>>((entry) async {
    final entity = entry.value;
    final previous = savedFiles[entry.key];

    return entity.map(
      directory: (serDir) async {
        if (!forceUpdate &&
            mapEquals(
              previous?.childEntities?.map(
                (key, value) => MapEntry(key, value.value),
              ),
              serDir.entities.asDirectoryMap(),
            )) {
          return [];
        }
        final dirResult = await directory.getOrReplaceDirectoryHandle(
          serDir.name,
        );

        return dirResult.when(
          ok: (newDir) async {
            final newSavedFiles = previous?.childEntities ?? {};

            savedFiles[entry.key] = _SavedEntity(
              value: entity,
              handle: newDir,
              childEntities: newSavedFiles,
            );

            final _errors = await saveDirectoryEntities(
              newDir,
              serDir.entities,
              newSavedFiles,
              forceUpdate: forceUpdate,
            );

            return _errors;
          },
          err: (err) => [err],
        );
      },
      file: (serializedFile) async {
        if (!forceUpdate && previous?.value == entity) {
          return [];
        }
        final file = await saveFile(directory, serializedFile);

        return file.when(
          ok: (file) {
            savedFiles[entry.key] = _SavedEntity(
              value: entity,
              handle: file,
            );
            return [];
          },
          err: (err) => [err],
        );
      },
    );
  });
  final saveErrors = (await Future.wait(_futs)).expand((e) => e);

  final _futsDelete = [...savedFiles.entries]
      .where((element) => !toSave.containsKey(element.key))
      .map((e) async {
    final fileHandle = e.value.handle;
    final result = await directory.removeEntry(
      fileHandle.name,
      recursive: true,
    );
    if (result.isOk) {
      savedFiles.remove(e.key);
    }
    return result;
  });
  final errors = (await Future.wait(_futsDelete))
      .whereType<Err<void, RemoveEntryError>>()
      .where((e) => e.error.type != RemoveEntryErrorType.NotFoundError)
      .map((e) => BaseFileError.castRemoveEntryError(e.error));

  return saveErrors.followedBy(errors).toList();
}

class _SavedEntity {
  final SerializedFileEntity value;
  final FileSystemHandle handle;
  final Map<String, _SavedEntity>? childEntities;

  _SavedEntity({
    required this.value,
    required this.handle,
    this.childEntities,
  });
}

extension EntitiesMap on List<SerializedFileEntity> {
  Map<String, SerializedFileEntity> asDirectoryMap() {
    return Map.fromEntries(map(
      (e) => MapEntry(e.name, e),
    ));
  }
}
