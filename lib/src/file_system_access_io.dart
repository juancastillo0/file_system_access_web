import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_system_access/file_system_access.dart';

abstract class FileSystemHandleIo extends FileSystemHandle {
  String get path;

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
    // final _currentSink = _sink;
    // _sink = null;
    // if (_currentSink != null) {
    // await _currentSink.flush();
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
    await data.when(
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
    return 'FileSystemWritableFileStreamIo(file: ${file}, '
        'keepExistingData:$keepExistingData, sink: ${sink})';
  }
}

class FileSystemFileHandleIo extends FileSystemHandleIo
    implements FileSystemFileHandle {
  final XFile file;

  FileSystemFileHandleIo(this.file);

  @override
  String get path => file.path;

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
  Future<void> remove({
    bool? recursive,
  }) async {
    await File(path).delete(recursive: recursive ?? false);
  }

  @override
  String toString() {
    return 'FileSystemFileHandleIo(file: ${file.path})';
  }
}

class FileSystemDirectoryHandleIo extends FileSystemHandleIo
    implements FileSystemDirectoryHandle {
  @override
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
  Future<void> remove({
    bool? recursive,
  }) async {
    await Directory(path).delete(recursive: recursive ?? false);
  }

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
  Future<FileSystemDirectoryHandle?> showDirectoryPicker([
    FsDirectoryOptions options = const FsDirectoryOptions(),
  ]) async {
    final path = await FilePicker.platform.getDirectoryPath(
      initialDirectory: _startInArg(options.startIn),
    );
    return path != null ? FileSystemDirectoryHandleIo(path) : null;
  }

  @override
  Future<List<FileSystemFileHandle>> showOpenFilePicker([
    FsOpenOptions options = const FsOpenOptions(),
  ]) async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: _allowedExtensions(options.types),
      type: _fileType(options.types),
      allowMultiple: options.multiple,
      initialDirectory: _startInArg(options.startIn),
    );
    if (result == null || result.count == 0) return [];
    final list = await Future.wait(result.files.map(_xFileFromPickerFile));
    return list.map((file) => FileSystemFileHandleIo(file)).toList();
  }

  @override
  Future<FileSystemFileHandle?> showSaveFilePicker([
    FsSaveOptions options = const FsSaveOptions(),
  ]) async {
    final String? filePath;
    if (Platform.isAndroid || Platform.isIOS) {
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: _allowedExtensions(options.types),
        type: _fileType(options.types),
        allowMultiple: false,
        initialDirectory: _startInArg(options.startIn),
      );
      filePath =
          result == null || result.count == 0 ? null : result.paths.first;
    } else {
      filePath = await FilePicker.platform.saveFile(
        allowedExtensions: _allowedExtensions(options.types),
        type: _fileType(options.types),
        fileName: options.suggestedName,
        initialDirectory: _startInArg(options.startIn),
      );
    }
    if (filePath == null) return null;
    return FileSystemFileHandleIo(XFile(filePath));
  }

  @override
  Future<FileSystemPersistance> getPersistance({
    String databaseName = 'FilesDB',
    String objectStoreName = 'FilesObjectStore',
  }) =>
      throw UnsupportedError(
        '`FileSystem.getPersistance()` is only supported for WEB.'
        ' You could save the Directory or File path in your'
        ' selected storage method for native platforms.',
      );

  @override
  StorageManager get storageManager => throw UnimplementedError(
        '`FileSystem.storageManager` is only implemented in WEB.',
      );

  @override
  Stream<DropFileEvent> webDropFileEvents() {
    throw UnimplementedError(
      '`FileSystem.webDropFileEvents` is only implemented in WEB.',
    );
  }

  @override
  FileSystemHandle? getIoNativeHandleFromPath(String path) {
    final type = FileSystemEntity.typeSync(path);

    if (type == FileSystemEntityType.file) {
      final file = XFile(path);
      return FileSystemFileHandleIo(file);
    } else if (type == FileSystemEntityType.directory) {
      return FileSystemDirectoryHandleIo(path);
    } else {
      return null;
    }
  }
}

const _kIsWeb = identical(0, 0.0);

Future<XFile> _xFileFromPickerFile(PlatformFile file) async {
  if (_kIsWeb) {
    final bytes = file.bytes ??
        Uint8List.fromList(
          (await file.readStream!.toList()).expand((e) => e).toList(),
        );

    return XFile.fromData(
      bytes,
      name: file.name,
      length: bytes.lengthInBytes,
    );
  } else {
    return XFile(
      file.path!,
      bytes: file.bytes,
      name: file.name,
      length: file.bytes?.lengthInBytes ?? file.size,
      lastModified: await File(file.path!)
          .lastModified()
          .then<DateTime?>((value) => value)
          .onError((error, stackTrace) => null),
      mimeType: null,
    );
  }
}

String? _startInArg(FsStartsInOptions? startIn) {
  return startIn?.path ?? (startIn?.handle as FileSystemHandleIo?)?.path;
}

List<String>? _allowedExtensions(List<FilePickerAcceptType>? types) {
  return types?.expand((t) => t.accept.values.expand((e) => e)).toList();
}

FileType _fileType(List<FilePickerAcceptType>? types) {
  FileType fileType = FileType.any;
  if (types != null && types.length == 1 && types.first.accept.length == 1) {
    final key = types.first.accept.keys.first;
    final index = FileType.values
        .indexWhere((element) => key.startsWith('${element.name}/'));
    if (index != -1) {
      fileType = FileType.values[index];
    }
  }

  return fileType;
}

// Future<PlatformFile> _pickerFileFromXFile(XFile file) async {
//   return PlatformFile(
//     bytes: _kIsWeb ? await file.readAsBytes() : null,
//     name: file.name,
//     size: await file.length(),
//     readStream: _kIsWeb ? null : file.openRead(),
//     path: file.path,
//   );
// }

// Future<int> length
// Future<DateTime> lastAccessed
// Future<DateTime> lastModified
// Stream<List<int>> openRead
// Future<Uint8List> readAsBytes
// String get path
