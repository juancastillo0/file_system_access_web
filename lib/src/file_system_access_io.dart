import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:file_selector/file_selector.dart';
import 'package:file_system_access/file_system_access.dart';

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
    return "FileSystemWritableFileStreamIo(file: ${file.toString()}, "
        "keepExistingData:$keepExistingData, sink: ${sink.toString()})";
  }
}

class FileSystemFileHandleIo extends FileSystemHandleIo
    implements FileSystemFileHandle {
  final XFile file;

  FileSystemFileHandleIo(this.file);

  @override
  String get name => file.name;

  @override
  Future<FileSystemWritableFileStream> createWritable(
      {bool? keepExistingData}) async {
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
    return "FileSystemFileHandleIo(file: ${file.toString()})";
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
  Future<FileSystemDirectoryHandleIo> getDirectoryHandle(String name,
      {bool? create}) async {
    return FileSystemDirectoryHandleIo(joinName(name));
  }

  @override
  Future<FileSystemFileHandle> getFileHandle(String name,
      {bool? create}) async {
    final file = XFile(joinName(name));
    return FileSystemFileHandleIo(file);
  }

  @override
  Future<void> removeEntry(String name, {bool? recursive}) async {
    await File(joinName(name)).delete(recursive: recursive ?? false);
    return;
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
    return "FileSystemDirectoryHandleIo(path: $path)";
  }
}

class FileSystem extends FileSystemI {
  const FileSystem._();

  static const FileSystem instance = FileSystem._();

  @override
  Future<FileSystemDirectoryHandle> showDirectoryPicker() async {
    final path = await FileSelectorPlatform.instance.getDirectoryPath();
    return FileSystemDirectoryHandleIo(path!);
  }

  @override
  Future<List<FileSystemFileHandle>> showOpenFilePicker(
      {List<FilePickerAcceptType>? types,
      bool? excludeAcceptAllOption,
      bool? multiple}) async {
    final files = await FileSelectorPlatform.instance.openFiles();
    return files.map((file) => FileSystemFileHandleIo(file)).toList();
  }

  @override
  Future<FileSystemFileHandle> showSaveFilePicker(
      {List<FilePickerAcceptType>? types, bool? excludeAcceptAllOption}) async {
    final file = await FileSelectorPlatform.instance.openFile();
    return FileSystemFileHandleIo(file!);
  }
}
