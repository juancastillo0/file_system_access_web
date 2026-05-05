// Type definitions for non-npm package File System Access API 2020.09
// Project: https://github.com/WICG/file-system-access
// Definitions by: Ingvar Stepanyan <https://github.com/RReverser>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped
// Minimum TypeScript Version: 3.5
@JS()
library file_system_access;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:file_system_access/file_system_access.dart';
import 'package:file_system_access/src/utils.dart';
import 'package:web/web.dart' as web;

// @JS()
// @anonymous
// class JsBlob {
//   external String get type;
//   external int get size;

//   // external JsBlob slice();
// }

// @JS()
// @anonymous
// class JsFile extends JsBlob {
//   external String get webkitRelativePath;
//   external String get name;
//   external DateTime get lastModifiedDate;
//   external int get lastModified;
// }

// @JS("FileReader")
// class _JsFileReader {
//   external String get error;
//   external int get readyState;
//   external dynamic get result;

//   external void Function() get onabort;
//   external set onabort(void Function() f);
//   external void Function() get onerror;
//   external set onerror(void Function() f);
//   external void Function() get onload;
//   external set onload(void Function() f);
//   external void Function() get onloadstart;
//   external set onloadstart(void Function() f);
//   external void Function() get onloadend;
//   external set onloadend(void Function() f);
//   external void Function() get onprogress;
//   external set onprogress(void Function() f);

//   external void abort();
//   external void readAsArrayBuffer(JsBlob blob);
//   external void readAsBinaryString(JsBlob blob);
//   external void readAsDataUrl(JsBlob blob);
//   external void readAsText(JsBlob blob);
// }

@JS('undefined')
external JSAny? get _undefinedValue;

@JS('FileSystemHandle')
extension type _FileSystemHandle._(JSObject _) implements JSObject {
  external String get kind;
  external String get name;

  external JSPromise<JSBoolean> isSameEntry(_FileSystemHandle other);
  external JSPromise<JSString /*PermissionStateEnum*/> queryPermission([
    _FileSystemHandlePermissionDescriptor? descriptor,
  ]);
  external JSPromise<JSString /*PermissionStateEnum*/> requestPermission([
    _FileSystemHandlePermissionDescriptor? descriptor,
  ]);
  external JSPromise<JSAny?> remove([_FileSystemHandleRemoveOptions? options]);
}

abstract class _FileSystemHandleJS extends FileSystemHandle {
  _FileSystemHandleJS(this.inner);

  final _FileSystemHandle inner;

  factory _FileSystemHandleJS.fromInner(_FileSystemHandle inner) =>
      inner.kind == FileSystemHandleKind.directory.name
      ? _FileSystemDirectoryHandleJS(inner as _FileSystemDirectoryHandle)
      : _FileSystemFileHandleJS(inner as _FileSystemFileHandle);

  @override
  Future<bool> isSameEntry(FileSystemHandle other) async {
    final result = await inner
        .isSameEntry((other as _FileSystemHandleJS).inner)
        .toDart;
    return result.toDart;
  }

  @override
  FileSystemHandleKind get kind => inner.kind == 'directory'
      ? FileSystemHandleKind.directory
      : FileSystemHandleKind.file;

  @override
  String get name => inner.name;

  @override
  Future<PermissionStateEnum> queryPermission({
    FileSystemPermissionMode? mode,
  }) async {
    final result = await inner
        .queryPermission(
          _FileSystemHandlePermissionDescriptor(
            mode: mode == null ? null : mode.toString().split('.')[1],
          ),
        )
        .toDart;
    return parseEnum(result.toDart, PermissionStateEnum.values)!;
  }

  @override
  Future<PermissionStateEnum> requestPermission({
    FileSystemPermissionMode? mode,
  }) async {
    final result = await inner
        .requestPermission(
          _FileSystemHandlePermissionDescriptor(
            mode: mode == null ? null : mode.toString().split('.')[1],
          ),
        )
        .toDart;
    return parseEnum(result.toDart, PermissionStateEnum.values)!;
  }

  @override
  Future<void> remove({bool? recursive}) =>
      inner.remove(_FileSystemHandleRemoveOptions(recursive: recursive)).toDart;

  @override
  String toString() {
    return 'FileSystemHandle(kind: ${inner.kind}, name: "$name")';
  }
}

extension type _FilePickerAcceptTypeJS._(JSObject _) implements JSObject {
  external _FilePickerAcceptTypeJS({
    String? description,
    required JSAny accept,
  });
  external String? get description;
  external JSAny get accept;
}

extension type _SaveFilePickerOptions._(JSObject _) implements JSObject {
  external _SaveFilePickerOptions({
    required JSArray<_FilePickerAcceptTypeJS> types,
    bool? excludeAcceptAllOption,
    String? suggestedName,
    JSAny? startIn,
    JSAny? id,
  });
  external JSArray<_FilePickerAcceptTypeJS>? get types;
  external bool? get excludeAcceptAllOption;
  external String? get suggestedName;
  external JSAny? get startIn;
  external JSAny? get id;
}

extension type _DirectoryPickerOptions._(JSObject _) implements JSObject {
  external _DirectoryPickerOptions({
    required String mode,
    JSAny? startIn,
    JSAny? id,
  });
  external String get mode;
  external JSAny? get startIn;
  external JSAny? get id;
}

extension type _OpenFilePickerOptions._(JSObject _) implements JSObject {
  external _OpenFilePickerOptions({
    bool? multiple,
    required JSArray<_FilePickerAcceptTypeJS> types,
    bool? excludeAcceptAllOption,
    JSAny? startIn,
    JSAny? id,
  });
  external bool? get multiple;
  external JSArray<_FilePickerAcceptTypeJS>? get types;
  external bool? get excludeAcceptAllOption;
  external JSAny? get startIn;
  external JSAny? get id;
}

extension type _FileSystemHandlePermissionDescriptor._(JSObject _)
    implements JSObject {
  external _FileSystemHandlePermissionDescriptor({String? mode});
  external String? get mode;
}

extension type _FileSystemHandleRemoveOptions._(JSObject _)
    implements JSObject {
  external _FileSystemHandleRemoveOptions({bool? recursive});
  external bool? get recursive;
}

extension type _FileSystemCreateWritableOptions._(JSObject _)
    implements JSObject {
  external _FileSystemCreateWritableOptions({bool? keepExistingData});
  external bool? get keepExistingData;
}

extension type _FileSystemGetFileOptions._(JSObject _) implements JSObject {
  external _FileSystemGetFileOptions({bool? create});
  external bool? get create;
}

extension type _FileSystemGetDirectoryOptions._(JSObject _)
    implements JSObject {
  external _FileSystemGetDirectoryOptions({bool? create});
  external bool? get create;
}

extension type _FileSystemRemoveOptions._(JSObject _) implements JSObject {
  external _FileSystemRemoveOptions({bool? recursive});
  external bool? get recursive;
}

extension type _WriteParams._(JSObject _) implements JSObject {
  external _WriteParams({
    required String? type,
    int? position,
    JSAny? data,
    int? size,
  });
  external String get type;
  external int? get position;
  external JSAny? get data;
  external int? get size;
}

extension type _Iterator<T extends JSAny?>._(JSObject _) implements JSObject {
  external T next();
}

extension type _IteratorValue<T extends JSAny?>._(JSObject _)
    implements JSObject {
  external bool get done;
  external T? get value;
}

// type FileSystemWriteChunkType = BufferSource | Blob | string | WriteParams;

@JS('FileSystemWritableFileStream')
extension type _FileSystemWritableFileStream._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> close();
  external JSPromise<JSAny?> write(JSAny? /*FileSystemWriteChunkType*/ data);
  external JSPromise<JSAny?> seek(int position);
  external JSPromise<JSAny?> truncate(int size);
}

class _FileSystemWritableFileStreamJS implements FileSystemWritableFileStream {
  const _FileSystemWritableFileStreamJS(this.inner);
  final _FileSystemWritableFileStream inner;

  @override
  Future<void> write(WriteChunkType data) {
    final jsValue = data.when<JSAny?>(
      writeParams: (writeParams) {
        final map = writeParams.toJson();
        return _WriteParams(
          type: map['type'] as String?,
          position: map['position'] as int?,
          data: (map['data'] as Object?).jsify(),
          size: map['size'] as int?,
        );
      },
      bufferSource: (value) => value.toJS,
      string: (value) => value.toJS,
    );
    return inner.write(jsValue).toDart;
  }

  @override
  Future<void> close() => inner.close().toDart;

  @override
  Future<void> seek(int position) => inner.seek(position).toDart;

  @override
  Future<void> truncate(int size) => inner.truncate(size).toDart;
}

@JS('FileSystemFileHandle')
extension type _FileSystemFileHandle._(JSObject _)
    implements _FileSystemHandle {
  external JSPromise<web.File> getFile();
  external JSPromise<_FileSystemWritableFileStream> createWritable([
    _FileSystemCreateWritableOptions? options,
  ]);
}

class _FileSystemFileHandleJS extends _FileSystemHandleJS
    implements FileSystemFileHandle {
  _FileSystemFileHandleJS(_FileSystemFileHandle super.inner);
  _FileSystemFileHandle get _inner => inner as _FileSystemFileHandle;

  @override
  Future<XFile> getFile() async {
    final result = await _inner.getFile().toDart;
    return _convertFileToXFile(result);
  }

  @override
  Future<FileSystemWritableFileStream> createWritable({
    bool? keepExistingData,
  }) async {
    final result = await _inner
        .createWritable(
          _FileSystemCreateWritableOptions(keepExistingData: keepExistingData),
        )
        .toDart;
    return _FileSystemWritableFileStreamJS(result);
  }
}

XFile _convertFileToXFile(web.File file) => XFile(
  web.URL.createObjectURL(file),
  name: file.name,
  length: file.size,
  lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified),
  mimeType: file.type,
);

@JS('FileSystemDirectoryHandle')
extension type _FileSystemDirectoryHandle._(JSObject _)
    implements _FileSystemHandle {
  external JSPromise<_FileSystemFileHandle> getFileHandle(
    String name, [
    _FileSystemGetFileOptions? options,
  ]);
  external JSPromise<_FileSystemDirectoryHandle> getDirectoryHandle(
    String name, [
    _FileSystemGetDirectoryOptions? options,
  ]);
  external JSPromise<JSAny?> removeEntry(
    String name, [
    _FileSystemRemoveOptions? options,
  ]);
  external JSPromise<JSArray<JSString>?> resolve(
    _FileSystemHandle possibleDescendant,
  );
  external _Iterator<JSPromise<_IteratorValue<_FileSystemHandle>>> values();
}

class StorageManagerJS implements StorageManager {
  final web.StorageManager inner;

  StorageManagerJS(this.inner);

  @override
  Future<bool> persisted() async {
    final result = await inner.persisted().toDart;
    return result.toDart;
  }

  @override
  Future<bool> persist() async {
    final result = await inner.persist().toDart;
    return result.toDart;
  }

  @override
  Future<StorageEstimate> estimate() async {
    final jsEstimate = await inner.estimate().toDart;
    return _StorageEstimate(
      quota: jsEstimate.quota,
      usage: jsEstimate.usage,
      usageDetails: const {},
    );
  }

  @override
  Future<FileSystemDirectoryHandle> getDirectory() async {
    final value = await _navigatorStorageGetDirectory().toDart;
    return _FileSystemDirectoryHandleJS(value);
  }
}

class _StorageEstimate implements StorageEstimate {
  @override
  final int usage;
  @override
  final int quota;
  @override
  final Map<String, int> usageDetails;

  _StorageEstimate({
    required this.usage,
    required this.quota,
    required this.usageDetails,
  });
}

GetHandleError _mapGetHandleError(
  FileSystemDirectoryHandle handle,
  String name,
  Object error,
  StackTrace stack,
) {
  GetHandleErrorType type = GetHandleErrorType.TypeError;
  if (error is JSObject && error.isA<web.DOMException>()) {
    type =
        GetHandleError.typeFromString((error as web.DOMException).name) ?? type;
  }

  return GetHandleError(
    type: type,
    rawError: error,
    rawStack: stack,
    handle: handle,
    name: name,
  );
}

RemoveEntryError _mapRemoveEntryError(
  FileSystemDirectoryHandle handle,
  String name,
  Object error,
  StackTrace stack,
) {
  RemoveEntryErrorType type = RemoveEntryErrorType.TypeError;
  if (error is JSObject && error.isA<web.DOMException>()) {
    type =
        RemoveEntryError.typeFromString((error as web.DOMException).name) ??
        type;
  }

  return RemoveEntryError(
    type: type,
    rawError: error,
    rawStack: stack,
    handle: handle,
    name: name,
  );
}

class _FileSystemDirectoryHandleJS extends _FileSystemHandleJS
    implements FileSystemDirectoryHandle {
  _FileSystemDirectoryHandleJS(_FileSystemDirectoryHandle super.inner);
  _FileSystemDirectoryHandle get _inner => inner as _FileSystemDirectoryHandle;

  @override
  Future<Result<FileSystemFileHandle, GetHandleError>> getFileHandle(
    String name, {
    bool? create,
  }) async {
    try {
      final value = await _inner
          .getFileHandle(name, _FileSystemGetFileOptions(create: create))
          .toDart;
      return Ok(_FileSystemFileHandleJS(value));
    } catch (error, stack) {
      return Err(_mapGetHandleError(this, name, error, stack));
    }
  }

  @override
  Future<Result<FileSystemDirectoryHandle, GetHandleError>> getDirectoryHandle(
    String name, {
    bool? create,
  }) async {
    try {
      final value = await _inner
          .getDirectoryHandle(
            name,
            _FileSystemGetDirectoryOptions(create: create),
          )
          .toDart;
      return Ok(_FileSystemDirectoryHandleJS(value));
    } catch (error, stack) {
      return Err(_mapGetHandleError(this, name, error, stack));
    }
  }

  @override
  Stream<FileSystemHandle> entries() {
    final entriesIterator = _inner.values();

    late final StreamController<FileSystemHandle> controller;
    int listening = 0;
    bool inLoop = false;

    Future<void> _loop() async {
      if (inLoop) {
        return;
      }
      inLoop = true;
      while (!controller.isClosed && listening > 0) {
        final entry = await entriesIterator.next().toDart;
        final handle = entry.value;
        if (handle != null) {
          final _entry = _FileSystemHandleJS.fromInner(handle);
          controller.add(_entry);
        }
        if (entry.done) {
          await controller.close();
        }
      }
      inLoop = false;
    }

    controller = StreamController(
      onPause: () {
        listening--;
      },
      onResume: () {
        listening++;
        _loop();
      },
      onListen: () {
        listening++;
        _loop();
      },
      onCancel: () {
        listening--;
      },
    );

    return controller.stream;
  }

  @override
  Future<Result<void, RemoveEntryError>> removeEntry(
    String name, {
    bool? recursive,
  }) {
    return _inner
        .removeEntry(name, _FileSystemRemoveOptions(recursive: recursive))
        .toDart
        .then<Result<void, RemoveEntryError>>((value) => const Ok(null))
        .catchError((Object error, StackTrace stack) {
          return Err<void, RemoveEntryError>(
            _mapRemoveEntryError(this, name, error, stack),
          );
        });
  }

  @override
  Future<List<String>?> resolve(FileSystemHandle possibleDescendant) async {
    final result = await _inner
        .resolve((possibleDescendant as _FileSystemHandleJS).inner)
        .toDart;
    return result?.toDart.map((e) => e.toDart).toList();
  }
}

// @JS()
// @anonymous
// class DataTransferItem {
//   external _Promise<
//       FileSystemHandle /*@optional*/
//       > getAsFileSystemHandle();
// }

// @JS()
// @anonymous
// class StorageManager {
//   external _Promise<FileSystemDirectoryHandle> getDirectory();
// }

@JS('showOpenFilePicker')
external JSPromise<JSArray<_FileSystemFileHandle>> _showOpenFilePicker([
  _OpenFilePickerOptions? options,
]);

@JS('showSaveFilePicker')
external JSPromise<_FileSystemFileHandle> _showSaveFilePicker([
  _SaveFilePickerOptions? options,
]);

@JS('showDirectoryPicker')
external JSPromise<_FileSystemDirectoryHandle> _showDirectoryPicker([
  _DirectoryPickerOptions? options,
]);

@JS('getFileSystemAccessFilePersistence')
external JSPromise<_FileSystemPersistence> _getFileSystemAccessFilePersistence([
  _FileSystemPersistenceParams? params,
]);

@JS('navigator.storage.getDirectory')
external JSPromise<_FileSystemDirectoryHandle> _navigatorStorageGetDirectory();

extension type _FileSystemPersistenceParams._(JSObject _) implements JSObject {
  external _FileSystemPersistenceParams({
    String? databaseName,
    String? objectStoreName,
  });
}

extension type _FileSystemPersistence._(JSObject _) implements JSObject {
  external _FileSystemPersistenceItem? get(int id);
  external JSArray<_FileSystemPersistenceItem> getAll();
  external JSPromise<_FileSystemPersistenceItem?> delete(int id);
  external JSPromise<_FileSystemPersistenceItem> put(JSAny? handle);
  external JSArray<JSNumber> keys();
}

@JS('Date')
extension type JSDate._(JSObject _) implements JSObject {
  external JSDate(int year, int month, int day);

  /// Milliseconds for this date since the epoch
  external int getTime();
  external String toISOString();
}

extension type _FileSystemPersistenceItem._(JSObject _) implements JSObject {
  external int get id;
  external JSObject? get value;
  external JSDate get savedDate;
}

class _FileSystemPersistenceJS implements FileSystemPersistence {
  final _FileSystemPersistence inner;

  _FileSystemPersistenceJS(this.inner);

  @override
  _FileSystemPersistenceItemJS? get(int id) {
    final value = inner.get(id);
    return value == null ? null : _FileSystemPersistenceItemJS(value);
  }

  @override
  List<_FileSystemPersistenceItemJS> getAll() =>
      inner.getAll().toDart.map(_FileSystemPersistenceItemJS.new).toList();

  @override
  Future<_FileSystemPersistenceItemJS?> delete(int id) =>
      inner.delete(id).toDart.then((value) {
        return value == null ? null : _FileSystemPersistenceItemJS(value);
      });

  @override
  Future<_FileSystemPersistenceItemJS> put(FileSystemHandle handle) => inner
      .put((handle as _FileSystemHandleJS).inner)
      .toDart
      .then((value) => _FileSystemPersistenceItemJS(value));

  @override
  Future<_FileSystemPersistenceItemJS> putFile(XFile file) async {
    final array = await file.readAsBytes();
    final _file = web.File(
      [array.buffer.toJS].toJS,
      file.name,
      web.FilePropertyBag(
        lastModified: (await file.lastModified()).millisecondsSinceEpoch,
        type: file.mimeType ?? '',
      ),
    );
    return inner.put(_file).toDart.then(_FileSystemPersistenceItemJS.new);
  }

  // Map<int, _FileSystemPersistenceItemJS> get allMap => inner.allMap
  //   .map((key, value) => MapEntry(key, _FileSystemPersistenceItemJS(value)));

  List<int> keys() => inner.keys().toDart.map((e) => e.toDartInt).toList();
}

class _FileSystemPersistenceItemJS with FileSystemPersistenceItem {
  final _FileSystemPersistenceItem inner;

  _FileSystemPersistenceItemJS(this.inner);

  @override
  int get id => inner.id;

  bool get isHandle {
    final value = inner.value;
    if (value == null) return false;
    return !value.has('digestSha1Hex');
  }

  @override
  late final FileSystemHandle? handle = isHandle
      ? _FileSystemHandleJS.fromInner(_FileSystemHandle._(inner.value!))
      : null;

  @override
  late final PersistedFile? persistedFile = isHandle
      ? null
      : _savedFileFromValue(inner.value!);

  @override
  DateTime get savedDate =>
      DateTime.fromMillisecondsSinceEpoch(inner.savedDate.getTime());

  @override
  String toString() {
    return 'FileSystemPersistenceItem(id: $id,'
        ' handle: $handle, persistedFile: $persistedFile,'
        ' savedDate: $savedDate)';
  }
}

PersistedFile _savedFileFromValue(JSObject jsObject) {
  return PersistedFile(
    name: (jsObject['name']! as JSString).toDart,
    mimeType: (jsObject['type']! as JSString).toDart,
    lastModified: DateTime.fromMillisecondsSinceEpoch(
      (jsObject['lastModified']! as JSNumber).toDartInt,
    ),
    arrayBuffer: (jsObject['arrayBuffer']! as JSArrayBuffer).toDart,
    digestSha1Hex: (jsObject['digestSha1Hex']! as JSString).toDart,
    webkitRelativePath: (jsObject['webkitRelativePath'] as JSString?)?.toDart,
  );
}

class FileSystem extends FileSystemI {
  const FileSystem._();

  static const FileSystem instance = FileSystem._();

  @override
  bool get isSupported => web.window.has('showOpenFilePicker');

  // @override
  // Future<String?> readFileAsText(dynamic file) {
  //   final reader = html.FileReader();
  //   final completer = Completer<String?>();
  //   void _c(String? v) => !completer.isCompleted? completer.complete(v):null;

  //   reader.onLoad.listen((e) {
  //     _c(reader.result as String?);
  //   });
  //   reader.onError.listen((event) {
  //     _c(null);
  //   });
  //   reader.onAbort.listen((event) {
  //     _c(null);
  //   });

  //   // final reader = _JsFileReader();
  //   // final completer = Completer<String>();
  //   // void _c(String v) => !completer.isCompleted ? completer.complete(v) : null;
  //   // reader.onload = allowInterop(() {
  //   //   _c(reader.result as String);
  //   // });
  //   // reader.onerror = allowInterop(() {
  //   //   _c(null);
  //   // });
  //   // reader.onabort = allowInterop(() {
  //   //   _c(null);
  //   // });
  //   reader.readAsText(file as html.File);

  //   return completer.future;
  // }

  static StreamController<DropFileEvent>? _dropFileEvents;

  @override
  Stream<DropFileEvent> webDropFileEvents() {
    if (_dropFileEvents != null) return _dropFileEvents!.stream;

    _dropFileEvents = StreamController<DropFileEvent>.broadcast();

    void Function(web.DragEvent) dragFunction(DropFileEventType type) {
      return (web.DragEvent e) {
        e.preventDefault();

        _dropFileEvents!.add(
          DropFileEvent(
            items: const [],
            type: type,
            clientX: e.clientX,
            clientY: e.clientY,
            pageX: e.pageX,
            pageY: e.pageY,
          ),
        );
      };
    }

    web.window.ondragover = dragFunction(DropFileEventType.dragOver).toJS;
    web.window.ondragenter = dragFunction(DropFileEventType.dragEnter).toJS;
    web.window.ondragleave = dragFunction(DropFileEventType.dragLeave).toJS;

    Future<FileSystemItemWebSafe?> handleFileSystemEntry(
      web.FileSystemEntry entry,
      FileSystemHandle? handle,
    ) async {
      if (entry.isDirectory) {
        final dir = entry as web.FileSystemDirectoryEntry;
        final completer = Completer<FileSystemItemWebSafe>();
        final h = handle as FileSystemDirectoryHandle?;
        dir.createReader().readEntries(
          ((JSArray<web.FileSystemEntry> entries) {
            Future.wait(
              entries.toDart.map((e) async {
                FileSystemHandle? entryHandle;
                if (h != null) {
                  final handle = await (e.isDirectory
                      ? h.getDirectoryHandle(e.name)
                      : h.getFileHandle(e.name));
                  entryHandle = handle.okOrNull;
                }
                return handleFileSystemEntry(e, entryHandle);
              }).toList(),
            ).then((children) {
              completer.complete(
                FileSystemDirectoryWebSafe(
                  children: children
                      .whereType<FileSystemItemWebSafe>()
                      .toList(),
                  name: dir.name,
                  path: dir.fullPath,
                  handle: h,
                ),
              );
            });
          }).toJS,
        );

        return completer.future;
      } else if (entry.isFile) {
        final f = entry as web.FileSystemFileEntry;
        final completer = Completer<FileSystemItemWebSafe>();
        f.file(
          ((web.File file) {
            file.arrayBuffer().toDart.then((data) {
              final xfile = XFile.fromData(
                data.toDart.asUint8List(),
                mimeType: file.type,
                name: file.name,
                length: file.size,
                lastModified: DateTime.fromMillisecondsSinceEpoch(
                  file.lastModified,
                ),
                path: f.fullPath,
              );
              completer.complete(
                FileSystemFileWebSafe(
                  file: xfile,
                  handle: handle as FileSystemFileHandle?,
                ),
              );
            });
          }).toJS,
        );

        return completer.future;
      }
      return null;
    }

    web.window.ondrop = ((web.DragEvent e) {
      if (_dropFileEvents == null) return;
      // prevent default action (open as a link for some elements)
      e.preventDefault();

      if (e.dataTransfer == null) return;
      final items = e.dataTransfer!.items;
      Future.wait(
        List.generate(items.length, (i) async {
          final item = items[i];
          final entry = item.webkitGetAsEntry()!;
          final handlePromise = FileSystem.instance.isSupported
              ? item.callMethod('getAsFileSystemHandle'.toJS)
              : null;
          FileSystemHandle? handle;
          if (handlePromise != null) {
            final jsHandle =
                (await (handlePromise as JSPromise<JSAny?>).toDart)!
                    as _FileSystemHandle;
            handle = _FileSystemHandleJS.fromInner(jsHandle);
          }
          return handleFileSystemEntry(entry, handle);
        }),
      ).then((files) {
        final mappedFiles = files.whereType<FileSystemItemWebSafe>().toList();
        if (mappedFiles.isNotEmpty) {
          _dropFileEvents!.add(
            DropFileEvent(
              items: mappedFiles,
              type: DropFileEventType.drop,
              clientX: e.clientX,
              clientY: e.clientY,
              pageX: e.pageX,
              pageY: e.pageY,
            ),
          );
        }
      });
    }).toJS;
    return _dropFileEvents!.stream;
  }

  @override
  Future<List<FileSystemFileHandle>> showOpenFilePicker([
    FsOpenOptions options = const FsOpenOptions(),
  ]) {
    final _promise = _showOpenFilePicker(
      _OpenFilePickerOptions(
        multiple: options.multiple,
        excludeAcceptAllOption: options.excludeAcceptAllOption,
        types: _mapFilePickerTypes(options.types).toJS,
        id: options.id?.toJS ?? _undefinedValue,
        startIn: _startInArg(options.startIn),
      ),
    );
    return _promise.toDart
        .then<List<FileSystemFileHandle>>(
          (value) => value.toDart.map(_FileSystemFileHandleJS.new).toList(),
        ) // TODO: distinguish AbortError from others (for example, unsupported)
        .onError((Object error, StackTrace _) {
          if (error is JSObject &&
              error.isA<web.DOMException>() &&
              (error as web.DOMException).code == web.DOMException.ABORT_ERR) {
            return <FileSystemFileHandle>[];
          }
          throw error;
        });
  }

  @override
  Future<FileSystemFileHandle?> showSaveFilePicker([
    FsSaveOptions options = const FsSaveOptions(),
  ]) =>
      _showSaveFilePicker(
        _SaveFilePickerOptions(
          excludeAcceptAllOption: options.excludeAcceptAllOption,
          types: _mapFilePickerTypes(options.types).toJS,
          suggestedName: options.suggestedName,
          id: options.id?.toJS ?? _undefinedValue,
          startIn: _startInArg(options.startIn),
        ),
      ).toDart.then<FileSystemFileHandle?>(_FileSystemFileHandleJS.new)
      // TODO: distinguish AbortError from others (for example, unsupported)
      .onError((Object error, _) {
        if (error is JSObject &&
            error.isA<web.DOMException>() &&
            (error as web.DOMException).code == web.DOMException.ABORT_ERR) {
          return null;
        }
        throw error;
      });

  @override
  Future<FileSystemDirectoryHandle?> showDirectoryPicker([
    FsDirectoryOptions options = const FsDirectoryOptions(),
  ]) =>
      _showDirectoryPicker(
            _DirectoryPickerOptions(
              mode: options.mode.name,
              id: options.id?.toJS ?? _undefinedValue,
              startIn: _startInArg(options.startIn),
            ),
          ).toDart
          .then<FileSystemDirectoryHandle?>(_FileSystemDirectoryHandleJS.new)
          // TODO: distinguish AbortError from others (for example, unsupported)
          .onError((Object error, _) {
            if (error is JSObject &&
                error.isA<web.DOMException>() &&
                (error as web.DOMException).code ==
                    web.DOMException.ABORT_ERR) {
              return null;
            }
            throw error;
          });

  static Future<FileSystemPersistence>? _persistence;

  @override
  Future<FileSystemPersistence> getPersistence({
    String databaseName = 'FilesDB',
    String objectStoreName = 'FilesObjectStore',
  }) => _persistence ??= _getFileSystemAccessFilePersistence(
    _FileSystemPersistenceParams(
      databaseName: databaseName,
      objectStoreName: objectStoreName,
    ),
  ).toDart.then(_FileSystemPersistenceJS.new);

  @override
  StorageManager get storageManager =>
      StorageManagerJS(web.window.navigator.storage);

  @override
  FileSystemHandle? getIoNativeHandleFromPath(String path) =>
      throw UnimplementedError(
        '`FileSystem.getIoNativeHandleFromPath` is only implemented in Native.',
      );
}

JSAny? _startInArg(FsStartsInOptions? startIn) {
  if (startIn == null) return _undefinedValue;
  if (startIn.path != null) return startIn.path!.toJS;
  if (startIn.handle != null) {
    return (startIn.handle! as _FileSystemHandleJS).inner;
  }
  return _undefinedValue;
}

///
/// UTILITIES
///

List<_FilePickerAcceptTypeJS> _mapFilePickerTypes(
  List<FilePickerAcceptType> list,
) {
  return list
      .map(
        (e) => _FilePickerAcceptTypeJS(
          accept: e.accept.jsify()!,
          description: e.description,
        ),
      )
      .toList();
}
