import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:file_system_access/file_system_access.dart';
import 'package:file_system_access/src/models/result.dart';

abstract class FileSystemHandleIo extends FileSystemHandle {
  @override
  Future<PermissionStateEnum> queryPermission(
      {FileSystemPermissionMode? mode}) async {
    return PermissionStateEnum.granted;
  }

  @override
  Future<PermissionStateEnum> requestPermission(
      {FileSystemPermissionMode? mode}) async {
    return PermissionStateEnum.granted;
  }
}

class FileSystemWritableFileStreamIo extends FileSystemWritableFileStream {
  final File file;
  final bool keepExistingData;
  final RandomAccessFile sink;

  FileSystemWritableFileStreamIo._(
    this.file, {
    required this.keepExistingData,
    required this.sink,
  });

  static Future<FileSystemWritableFileStreamIo> fromFile(
    File file, {
    required bool keepExistingData,
  }) async {
    final RandomAccessFile _sink;
    if (keepExistingData) {
      _sink = await file.open(mode: FileMode.append);
      await _sink.setPosition(0);
    } else {
      _sink = await file.open(mode: FileMode.write);
    }
    return FileSystemWritableFileStreamIo._(
      file,
      keepExistingData: keepExistingData,
      sink: _sink,
    );
  }

  @override
  Future<void> close() async {
    // final _currSink = _sink;
    // _sink = null;
    // if (_currSink != null) {
    // await _currSink.flush();
    return sink.close();
    // }
  }

  @override
  Future<void> seek(int position) async {
    await sink.setPosition(position);
  }

  @override
  Future<void> truncate(int size) async {
    await sink.truncate(size);
  }

  @override
  Future<void> write(FileSystemWriteChunkType data) async {
    return data.when(
      bufferSource: (bufferSource) {
        return sink.writeFrom(bufferSource.asUint8List());
      },
      string: (string) {
        return sink.writeString(string);
      },
      writeParams: (writeParams) {
        writeParams.when(
          write: (write, position) async {
            if (position != null) {
              await this.seek(position);
            }
            return this.write(write);
          },
          seek: (seek) {
            return this.seek(seek);
          },
          truncate: (truncate) {
            return this.truncate(truncate);
          },
        );
      },
    );
  }

  @override
  String toString() {
    return 'FileSystemWritableFileStreamIo(file: ${file.toString()}, '
        'keepExistingData:$keepExistingData, sink: ${sink.toString()})';
  }
}

class FileSystemFileHandleIo extends FileSystemHandleIo
    implements FileSystemFileHandle {
  final XFile file;

  FileSystemFileHandleIo(this.file);

  @override
  String get name => file.name;

  @override
  Future<FileSystemWritableFileStream> createWritable({
    bool? keepExistingData,
  }) async {
    return FileSystemWritableFileStreamIo.fromFile(
      File(file.path),
      keepExistingData: keepExistingData ?? false,
    );
  }

  @override
  Future<XFile> getFile() async {
    return file;
  }

  @override
  final FileSystemHandleKind kind = FileSystemHandleKind.file;

  @override
  Future<bool> isSameEntry(FileSystemHandle other) async {
    if (other is FileSystemFileHandleIo) {
      return other.file.path == file.path && other.file.name == file.name;
    }
    return false;
  }

  @override
  String toString() {
    return 'FileSystemFileHandleIo(file: ${file.toString()})';
  }
}

class FileSystemDirectoryHandleIo extends FileSystemHandleIo
    implements FileSystemDirectoryHandle {
  final String path;

  FileSystemDirectoryHandleIo(this.path);

  late final uri = Uri.directory(path);

  @override
  String get name => path;

  @override
  Future<Result<FileSystemDirectoryHandle, GetHandleError>> getDirectoryHandle(
    String name, {
    bool? create,
  }) async {
    final concatName = joinName(name);
    final type = await FileSystemEntity.type(concatName);

    final _makeError = GetHandleError.errorMaker(this, name);

    if (type == FileSystemEntityType.directory) {
      return Ok(FileSystemDirectoryHandleIo(concatName));
    } else if (type == FileSystemEntityType.notFound) {
      if (create == true) {
        try {
          await Directory(concatName).create(recursive: true);
          return Ok(FileSystemDirectoryHandleIo(concatName));
        } catch (error, stack) {
          return Err(
            _makeError(GetHandleErrorType.TypeError, error, stack),
          );
        }
      } else {
        return Err(_makeError(GetHandleErrorType.NotFoundError));
      }
    } else {
      return Err(_makeError(GetHandleErrorType.TypeMismatchError));
    }
  }

  @override
  Future<Result<FileSystemFileHandle, GetHandleError>> getFileHandle(
    String name, {
    bool? create,
  }) async {
    final concatName = joinName(name);
    final type = await FileSystemEntity.type(concatName);

    final _makeError = GetHandleError.errorMaker(this, name);

    if (type == FileSystemEntityType.file) {
      final file = XFile(concatName);
      return Ok(FileSystemFileHandleIo(file));
    } else if (type == FileSystemEntityType.notFound) {
      if (create == true) {
        try {
          await File(concatName).create();
          final file = XFile(concatName);
          return Ok(FileSystemFileHandleIo(file));
        } catch (error, stack) {
          return Err(_makeError(GetHandleErrorType.TypeError, error, stack));
        }
      } else {
        return Err(_makeError(GetHandleErrorType.NotFoundError));
      }
    } else {
      return Err(_makeError(GetHandleErrorType.TypeMismatchError));
    }
  }

  @override
  Future<Result<void, RemoveEntryError>> removeEntry(
    String name, {
    bool? recursive,
  }) async {
    final concatName = joinName(name);
    final type = await FileSystemEntity.type(concatName);

    final _makeError = RemoveEntryError.errorMaker(this, name);

    late final FileSystemEntity entity;
    switch (type) {
      case FileSystemEntityType.notFound:
        return Err(_makeError(RemoveEntryErrorType.NotFoundError));
      case FileSystemEntityType.file:
        entity = File(concatName);
        break;
      case FileSystemEntityType.directory:
        final dir = Directory(concatName);
        if (recursive != true) {
          final isEmpty = await dir.list().isEmpty;
          if (!isEmpty) {
            return Err(_makeError(
              RemoveEntryErrorType.InvalidModificationError,
            ));
          }
        }
        entity = dir;
        break;
      case FileSystemEntityType.link:
        entity = Link(concatName);
        break;
    }
    await entity.delete(recursive: recursive ?? false);
    return const Ok(null);
  }

  @override
  Stream<FileSystemHandle> entries() {
    final dir = Directory(path);
    return dir.list().map((event) {
      if (event is File) {
        final file = XFile(event.path);
        return FileSystemFileHandleIo(file);
      } else if (event is Directory) {
        return FileSystemDirectoryHandleIo(event.path);
      } else {
        throw Error();
      }
    });
  }

  @override
  Future<List<String>?> resolve(FileSystemHandle possibleDescendant) async {
    if (possibleDescendant is FileSystemFileHandleIo) {
      return uri
          .resolveUri(Uri.file(possibleDescendant.file.path))
          .pathSegments;
    } else if (possibleDescendant is FileSystemDirectoryHandleIo) {
      return uri.resolveUri(possibleDescendant.uri).pathSegments;
    }
    return null;
  }

  @override
  Future<bool> isSameEntry(FileSystemHandle other) async {
    if (other is FileSystemDirectoryHandleIo) {
      return other.path == path;
    }
    return false;
  }

  String joinName(String name) {
    return '$path${Platform.pathSeparator}$name';
  }

  @override
  final FileSystemHandleKind kind = FileSystemHandleKind.directory;

  @override
  String toString() {
    return 'FileSystemDirectoryHandleIo(path: $path)';
  }
}

class FileSystem extends FileSystemI {
  const FileSystem._();

  static const FileSystem instance = FileSystem._();

  @override
  bool get isSupported => true;

  @override
  Future<FileSystemDirectoryHandle?> showDirectoryPicker() async {
    final path = await FileSelectorPlatform.instance.getDirectoryPath();
    return path != null ? FileSystemDirectoryHandleIo(path) : null;
  }

  @override
  Future<List<FileSystemFileHandle>> showOpenFilePicker({
    List<FilePickerAcceptType>? types,
    bool? excludeAcceptAllOption,
    bool? multiple,
  }) async {
    final files = await FileSelectorPlatform.instance.openFiles();
    return files.map((file) => FileSystemFileHandleIo(file)).toList();
  }

  @override
  Future<FileSystemFileHandle?> showSaveFilePicker({
    List<FilePickerAcceptType>? types,
    bool? excludeAcceptAllOption,
  }) async {
    final file = await FileSelectorPlatform.instance.openFile();
    return file != null ? FileSystemFileHandleIo(file) : null;
  }
}
