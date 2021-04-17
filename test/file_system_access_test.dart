import 'package:test/test.dart';

import 'package:file_system_access/file_system_access.dart';

void main() {
  test('adds one to input values', () async {
    final instance = FileSystem.instance;
    if (instance != null) {
      final handle = await instance.showOpenFilePicker();
      expect(handle.length, 1);
      final fileHandle = handle.first;
      expect(fileHandle.kind, FileSystemHandleKind.file);
    }
  });
}
