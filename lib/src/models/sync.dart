import 'dart:async';

import 'package:file_system_access/src/file_system_access.dart';
import 'package:file_system_access/src/models/serialized_entity.dart';
import 'package:file_system_access/src/utils.dart';

class DirectorySyncResult {
  DirectorySyncResult({
    required this.deleteErrors,
    required this.saveResults,
    required this.stats,
    required this.directoryHandle,
  });

  bool get hasErrors => stats.deleteErrors != 0 || stats.saveErrors != 0;

  final List<BaseFileError> deleteErrors;
  final List<SavedEntityResult> saveResults;
  final DirectorySyncStats stats;
  final FileSystemDirectoryHandle directoryHandle;

  final timestamp = DateTime.now();
}

class DirectorySyncStats {
  final int cachedFiles;
  final int updatedFiles;
  final int saveErrors;
  final int deleteErrors;

  DirectorySyncStats({
    required this.cachedFiles,
    required this.updatedFiles,
    required this.saveErrors,
    required this.deleteErrors,
  });

  factory DirectorySyncStats.fromData(
    List<SavedEntityResult> saveResults,
    List<BaseFileError> deleteErrorsList,
  ) {
    int cachedFiles = 0;
    int updatedFiles = 0;
    int saveErrors = 0;
    int deleteErrors = deleteErrorsList.length;

    for (final result in saveResults) {
      if (result.wasCached) {
        cachedFiles += 1;
      } else if (result.error == null) {
        updatedFiles += 1;
      } else {
        saveErrors += 1;
      }
    }
    final childStats = saveResults
        .map((r) => r.directoryResult?.stats)
        .whereType<DirectorySyncStats>();

    for (final _stats in childStats) {
      cachedFiles += _stats.cachedFiles;
      updatedFiles += _stats.updatedFiles;
      saveErrors += _stats.saveErrors;
      deleteErrors += _stats.deleteErrors;
    }

    return DirectorySyncStats(
      cachedFiles: cachedFiles,
      updatedFiles: updatedFiles,
      saveErrors: saveErrors,
      deleteErrors: deleteErrors,
    );
  }
}

class DirectorySynchronizer {
  FileSystemDirectoryHandle? _directoryHandle;
  FileSystemDirectoryHandle? get directoryHandle => _directoryHandle;

  final List<SerializedFileEntity> Function() getSerializedEntities;
  Duration? syncDuration;
  Timer? _timer;

  DirectorySynchronizer({
    required this.getSerializedEntities,
    this.syncDuration,
  }) {
    restartSync();
  }

  final _syncResultsController = StreamController<DirectorySyncResult>();
  Stream<DirectorySyncResult> get syncResults => _syncResultsController.stream;
  DirectorySyncResult? _lastSyncResult;
  DirectorySyncResult? get lastSyncResult => _lastSyncResult;

  final Map<String, SavedEntity> _savedFiles = {};

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
    return _syncResultsController.close();
  }

  /// Returns false if FileSystemPermissionMode.readwrite is not granted
  Future<bool> selectDirectory(
    FileSystemDirectoryHandle directory,
  ) async {
    final success = await FileSystem.instance.verifyPermission(
      directory,
      mode: FileSystemPermissionMode.readwrite,
    );

    if (!success) {
      return false;
    }
    if (directoryHandle != null) {
      if (await directoryHandle!.isSameEntry(directory)) {
        return true;
      } else {
        _savedFiles.clear();
      }
    }
    _directoryHandle = directory;
    _syncFuture = null;
    _lastSyncResult = null;
    return true;
  }

  Future<DirectorySyncResult>? _syncFuture;

  Future<DirectorySyncResult> saveEntities({
    bool forceUpdate = false,
  }) async {
    if (_syncFuture != null) {
      return _syncFuture!;
    }
    final _comp = Completer<DirectorySyncResult>();
    _syncFuture = _comp.future;
    final serialized = getSerializedEntities();

    final result = await _saveDirectoryEntities(
      directoryHandle!,
      serialized,
      _savedFiles,
      forceUpdate: forceUpdate,
    );

    if (_comp.future == _syncFuture) {
      _syncFuture = null;
      _lastSyncResult = result;
      _syncResultsController.add(result);
    }
    _comp.complete(result);
    return result;
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
        WriteChunkType.bufferSource(serializedFile.content.buffer),
      );
      await writable.close();

      return ok;
    },
    err: (err) => err,
  );
}

Future<DirectorySyncResult> _saveDirectoryEntities(
  FileSystemDirectoryHandle directory,
  List<SerializedFileEntity> serialized,
  Map<String, SavedEntity> savedFiles, {
  bool forceUpdate = false,
}) async {
  final toSave = serialized.asDirectoryMap();

  final _futs = toSave.entries.map<Future<SavedEntityResult>>((entry) async {
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
          return SavedEntityResult(entity: previous, wasCached: true);
        }
        final dirResult = await directory.getOrReplaceDirectoryHandle(
          serDir.name,
        );

        return dirResult.when(
          ok: (newDir) async {
            final newSavedFiles = previous?.childEntities ?? {};

            final _savedEntity = SavedEntity(
              value: entity,
              handle: newDir,
              childEntities: newSavedFiles,
            );
            savedFiles[entry.key] = _savedEntity;

            final _result = await _saveDirectoryEntities(
              newDir,
              serDir.entities,
              newSavedFiles,
              forceUpdate: forceUpdate,
            );

            return SavedEntityResult(
              directoryResult: _result,
              wasCached: false,
              entity: _savedEntity,
            );
          },
          err: (err) => SavedEntityResult.fromError(err),
        );
      },
      file: (serializedFile) async {
        if (!forceUpdate && previous?.value == entity) {
          return SavedEntityResult(entity: previous, wasCached: true);
        }
        final file = await saveFile(directory, serializedFile);

        return file.when(
          ok: (file) {
            final _savedEntity = SavedEntity(
              value: entity,
              handle: file,
            );
            savedFiles[entry.key] = _savedEntity;
            return SavedEntityResult(
              wasCached: false,
              entity: _savedEntity,
            );
          },
          err: (err) => SavedEntityResult.fromError(err),
        );
      },
    );
  });
  final saveResults = await Future.wait(_futs);

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
  final deleteErrors = (await Future.wait(_futsDelete))
      .whereType<Err<void, RemoveEntryError>>()
      .where((e) => e.error.type != RemoveEntryErrorType.NotFoundError)
      .map((e) => BaseFileError.castRemoveEntryError(e.error))
      .toList();

  final stats = DirectorySyncStats.fromData(saveResults, deleteErrors);
  return DirectorySyncResult(
    stats: stats,
    deleteErrors: deleteErrors,
    directoryHandle: directory,
    saveResults: saveResults,
  );
}

class SavedEntity {
  final SerializedFileEntity value;
  final FileSystemHandle handle;

  /// Only for directories
  final Map<String, SavedEntity>? childEntities;
  final timestamp = DateTime.now();

  SavedEntity({
    required this.value,
    required this.handle,
    this.childEntities,
  });
}

extension EntitiesMap on List<SerializedFileEntity> {
  Map<String, SerializedFileEntity> asDirectoryMap() {
    return Map.fromEntries(
      map(
        (e) => MapEntry(e.name, e),
      ),
    );
  }
}

class SavedEntityResult {
  final bool wasCached;
  final SavedEntity? entity;
  final BaseFileError? error;

  /// Only for directories
  final DirectorySyncResult? directoryResult;

  const SavedEntityResult({
    required this.wasCached,
    this.error,
    required this.entity,
    this.directoryResult,
  });

  const SavedEntityResult.fromError(this.error)
      : this.entity = null,
        this.wasCached = false,
        this.directoryResult = null;
}
