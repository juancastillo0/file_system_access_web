import 'package:file_system_access/file_system_access.dart';
import 'package:test/test.dart';

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
    final _directoryHandle = await FileSystem.instance.showDirectoryPicker();
    final directoryHandle = _directoryHandle!;
    expect(directoryHandle.kind, FileSystemHandleKind.directory);

    const _fileName = 'fileName.txt';

    final fileHandleResult = await directoryHandle.getFileHandle(
      _fileName,
      create: true,
    );
    await fileHandleResult.when(
      ok: (fileHandle) async {
        expect(fileHandle.name, _fileName);

        final pathSegments = await directoryHandle.resolve(fileHandle);

        expect(pathSegments!.length, 1);
        expect(pathSegments.first, _fileName);

        final file = await fileHandle.getFile();
        final content = await file.readAsString();

        final writable =
            await fileHandle.createWritable(keepExistingData: true);

        await writable.seek(content.length);
        await writable.write(
            const FileSystemWriteChunkType.string('\nAPPENDED_NEW_LINE_STR'));
        await writable.close();
      },
      err: (error) async {
        print(error);
      },
    );
  });
}
