import 'package:test/test.dart';

import 'package:file_system_access/file_system_access.dart';

void main() {
  test('open one file', () async {
    final handles = await FileSystem.instance.showOpenFilePicker(
      excludeAcceptAllOption: false,
      multiple: false,
    );
    expect(handles.length, 1);
    final fileHandle = handles.first;
    expect(fileHandle.kind, FileSystemHandleKind.file);
  });

  test('open file from directory handle and append a string into the file',
      () async {
    final directoryHandle = await FileSystem.instance.showDirectoryPicker();
    expect(directoryHandle.kind, FileSystemHandleKind.directory);

    const _fileName = "fileName.txt";

    final fileHandle = await directoryHandle.getFileHandle(
      _fileName,
      create: true,
    );
    expect(fileHandle.name, _fileName);

    final pathSegments = await directoryHandle.resolve(fileHandle);

    expect(pathSegments!.length, 1);
    expect(pathSegments.first, _fileName);

    final file = await fileHandle.getFile();
    final content = await file.readAsString();

    final writable = await fileHandle.createWritable(keepExistingData: true);

    await writable.seek(content.length);
    await writable
        .write(FileSystemWriteChunkType.string("\nAPPENDED_NEW_LINE_STRING"));
    await writable.close();
  });
}
