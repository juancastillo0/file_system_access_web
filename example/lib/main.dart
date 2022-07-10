import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:idb_shim/idb_shim.dart' as idb;
import 'package:url_launcher/link.dart';

import 'package:file_system_access/file_system_access.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File System Access',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const MyHomePage(title: 'File System Access'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final state = AppState();
  final textController = TextEditingController();
  bool get isDeleting => handlesToDelete != null;
  Map<String, FileSystemHandle>? handlesToDelete;

  StreamSubscription<String>? _errorSubs;
  StreamSubscription<String>? _editingFileTextSubs;

  _onUpdate() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    state.addListener(_onUpdate);
    _errorSubs = state.errorsStream.listen((event) {
      late final ScaffoldFeatureController controller;
      final snackbar = SnackBar(
        backgroundColor: Colors.red,
        width: 400,
        behavior: SnackBarBehavior.floating,
        content: Text(event),
        action: SnackBarAction(
          textColor: Colors.white,
          label: 'Close',
          onPressed: () {
            controller.close();
          },
        ),
      );

      controller = ScaffoldMessenger.of(context).showSnackBar(snackbar);
    });

    _editingFileTextSubs = state.editingFileTextStream.listen((event) {
      textController.text = event;
    });
  }

  @override
  void dispose() {
    _errorSubs?.cancel();
    _editingFileTextSubs?.cancel();
    state.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isHorizontal = mq.size.width > 1100;
    int _index = -1;

    Widget child = Flex(
      direction: isHorizontal ? Axis.horizontal : Axis.vertical,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _directoryWidget(),
        _selectFilesWidget(),
        _currentFileWidget(),
      ]
          .expand(
            (e) sync* {
              final _inner = Padding(
                padding: const EdgeInsets.all(10),
                child: e,
              );
              _index++;

              yield isHorizontal ? const VerticalDivider() : const Divider();
              if (isHorizontal) {
                yield Expanded(
                  flex: _index == 1 ? 3 : 2,
                  child: _inner,
                );
              } else {
                yield Center(
                  child: SizedBox(
                    height: 320,
                    width: mq.size.width < 600 ? mq.size.width : 600,
                    child: _inner,
                  ),
                );
              }
            },
          )
          .skip(1)
          .toList(),
    );

    if (!isHorizontal) {
      child = SingleChildScrollView(child: child);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        actions: [
          Link(
            target: LinkTarget.blank,
            uri: Uri.parse(
              'https://developer.mozilla.org/docs/Web/API/File_System_Access_API',
            ),
            builder: (context, launch) => TextButton(
              style: TextButton.styleFrom(primary: Colors.white),
              onPressed: launch,
              child: const Text('Mozilla Docs'),
            ),
          ),
          Link(
            target: LinkTarget.blank,
            uri: Uri.parse(
              'https://github.com/juancastillo0/file_system_access_web',
            ),
            builder: (context, launch) => TextButton(
              style: TextButton.styleFrom(primary: Colors.white),
              onPressed: launch,
              child: const Text('Github'),
            ),
          ),
        ],
        title: Text(widget.title),
      ),
      body: child,

      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _directoryWidget() {
    return Column(
      children: [
        Text('Is supported: ${FileSystem.instance.isSupported}'),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: state.selectDirectory,
            child: const Text('Select Directory'),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: (state.selectedDirectory.value != null)
                ? _selectedDirectoryWidget()
                : const Text('No directory selected'),
          ),
        ),
      ],
    );
  }

  Widget _selectedDirectoryWidget() {
    return FutureBuilder<List<FileSystemHandle>>(
      future: state.selectedDirectoryEntries,
      builder: ((context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Text('Directory Error - ${snapshot.error}'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    state.computeEverything();
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _directoryTitleWidget(snapshot.data!.length),
            const Divider(),
            if (snapshot.data!.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Empty directory',
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  ...snapshot.data!.map(
                    (e) => Row(
                      children: [
                        if (handlesToDelete != null)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Checkbox(
                              value: handlesToDelete!
                                  .containsKey(state.resolve(e)),
                              onChanged: (v) {
                                setState(() {
                                  final key = state.resolve(e);
                                  if (v == false) {
                                    handlesToDelete!.remove(key);
                                  } else {
                                    handlesToDelete![key] = e;
                                  }
                                });
                              },
                            ),
                          )
                        else if (e is FileSystemFileHandle)
                          IconButton(
                            splashRadius: 18,
                            iconSize: 18,
                            onPressed: () {
                              state.selectFileForEdit(e);
                            },
                            icon: const Icon(Icons.edit),
                          )
                        else if (e is FileSystemDirectoryHandle)
                          IconButton(
                            splashRadius: 18,
                            iconSize: 18,
                            onPressed: () {
                              state.viewInnerDirectory(e);
                            },
                            icon: const Icon(Icons.folder_open),
                          ),
                        Expanded(
                          child: SelectableText('${e.name} (${e.kind.name})'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _directoryTitleWidget(int length) {
    final dir = state.selectedDirectory.value!;
    return Row(
      children: [
        if (state.directoryStack.value.isNotEmpty)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              state.popDirectoryFromStack();
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.arrow_back),
            ),
          )
        else
          const SizedBox(width: 32),
        Expanded(
          child: Center(
            child: Text(
              '"${dir.name}" - $length items',
            ),
          ),
        ),
        if (isDeleting)
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              setState(() {
                handlesToDelete = null;
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close),
            ),
          )
        else
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final FileSystemCreateItemInfo? info =
                  await showFileItemCreateDialog();
              if (info == null) return;
              state.createItemInDirectory(
                info.name,
                info.kind,
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.note_add),
            ),
          ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            setState(() {
              final _handles = handlesToDelete;
              if (_handles != null && _handles.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(
                      'Are you sure you want to delete ${_handles.length} items?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          state.deleteItems(_handles.values.toList());
                          setState(() {
                            handlesToDelete = null;
                          });
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              } else {
                handlesToDelete = {};
              }
            });
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.delete),
          ),
        ),
      ],
    );
  }

  Future<FileSystemCreateItemInfo?> showFileItemCreateDialog() async {
    String name = '';
    final kind = ValueNotifier(FileSystemHandleKind.file);

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                onChanged: (_name) {
                  name = _name;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ValueListenableBuilder<FileSystemHandleKind>(
                  valueListenable: kind,
                  builder: (context, value, _) {
                    return Row(
                      children: [
                        const Text('File'),
                        Radio<FileSystemHandleKind>(
                          value: FileSystemHandleKind.file,
                          groupValue: kind.value,
                          onChanged: (v) {
                            kind.value = v!;
                          },
                        ),
                        const SizedBox(width: 10),
                        const Text('Directory'),
                        Radio<FileSystemHandleKind>(
                          value: FileSystemHandleKind.directory,
                          groupValue: kind.value,
                          onChanged: (v) {
                            kind.value = v!;
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    name = name.trim();
    if (result != true || name.isEmpty) {
      return null;
    }
    return FileSystemCreateItemInfo(name: name, kind: kind.value);
  }

  Widget _selectFilesWidget() {
    const _headersPadding = EdgeInsets.all(3);
    Widget _header(String text) {
      return Padding(
        padding: _headersPadding,
        child: SelectableText(
          text,
          style: Theme.of(context)
              .textTheme
              .subtitle1!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Multiple'),
                Switch(
                  value: state.multiple.value,
                  onChanged: (v) {
                    state.multiple.value = v;
                  },
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Only Images'),
                Switch(
                  value: state.onlyImages.value,
                  onChanged: (v) {
                    state.onlyImages.value = v;
                  },
                ),
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: state.selectFiles,
            child: const Text('Select Files'),
          ),
        ),
        if (state.selectedFilesDesc == null)
          const SizedBox()
        else if (state.selectedFilesDesc!.value == null)
          requestUserActivationWidget(state.selectedFilesDesc!)
        else
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                columnWidths: const {
                  3: FixedColumnWidth(80),
                  4: FixedColumnWidth(70),
                },
                border: TableBorder.all(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    // decoration: const BoxDecoration(
                    //   border: Border.fromBorderSide(BorderSide()),
                    // ),
                    children: [
                      _header('Name'),
                      _header('MimeType'),
                      _header('LastModified'),
                      _header('Bytes'),
                      _header('Action'),
                    ],
                  ),
                  ...state.selectedFilesDesc!.value!.map(
                    (e) => TableRow(
                      // decoration: const BoxDecoration(
                      //   border: Border.fromBorderSide(BorderSide()),
                      // ),
                      children: [
                        SelectableText(e.name),
                        SelectableText(e.mimeType ?? ''),
                        SelectableText(e.lastModified
                            .toIso8601String()
                            .replaceFirst('T', '\n')),
                        SelectableText(e.humanReadableBytes),
                        (e.mimeType ?? '').startsWith('image/')
                            ? InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: Image.network(e.file.path),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Image.network(e.file.path),
                              )
                            : InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  state.selectFileForEdit(e.handle);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.edit),
                                ),
                              ),
                      ]
                          .map(
                            (e) => Padding(padding: _headersPadding, child: e),
                          )
                          .toList(),
                    ),
                  )
                ],
              ),
            ),
          )
      ],
    );
  }

  Widget _currentFileWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                state.selectCurrentFile(create: false);
              },
              child: const Text('Edit File'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                state.selectCurrentFile(create: true);
              },
              child: const Text('Create File'),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      controller: textController,
                      // expands: true,
                      maxLines: 100000,
                      minLines: null,
                    ),
                  ),
                ),
                (state.selectedFileForSaveDesc != null)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          (() {
                            final result = state.selectedFileForSaveDesc!;
                            final desc = result.value;
                            if (desc == null) {
                              return requestUserActivationWidget(result);
                            }
                            final _mime =
                                desc.mimeType == null || desc.mimeType!.isEmpty
                                    ? ''
                                    : ' (${desc.mimeType})';
                            return SelectableText(
                              '"${desc.name}"$_mime - ${desc.humanReadableBytes}\n${desc.lastModified}',
                            );
                          })(),
                          ElevatedButton(
                            onPressed: () =>
                                state.saveFile(textController.text),
                            child: const Text('Save File'),
                          ),
                        ],
                      )
                    : const Text('No file selected'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget requestUserActivationWidget(
    FileSystemItemsStatus result,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14.0),
          child: Text(
            'Keep ${result.mode == FileSystemPermissionMode.readwrite ? 'editing' : 'viewing'}'
            ' ${result.items.take(5).map((e) => '"${e.name}" (${e.kind.name})').join(', ')}'
            '${result.items.length > 5 ? ' and ${result.items.length - 5} more.' : ''}',
          ),
        ),
        OutlinedButton(
          onPressed: state.computeEverything,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class AppState extends ChangeNotifier {
  AppState() {
    _setUpListeners();
    _setUpDB();
  }

  idb.Database? db;

  void _setUpListeners() {
    for (final n in allNotifiers) {
      n.addListener(notifyListeners);
    }

    selectedFiles.addListener(computeSelectedFilesDesc);
    selectedFileForSave.addListener(computeSelectedFileForSaveDesc);
    selectedDirectory.addListener(computeSelectedDirectoryEntries);
    editingFileTextStream.listen((event) {
      _editingFileTextLastValue = event;
    });
  }

  void computeEverything() {
    computeSelectedFilesDesc();
    computeSelectedFileForSaveDesc();
    computeSelectedDirectoryEntries();
  }

  void computeSelectedFilesDesc() async {
    if (selectedFiles.value == null) {
      selectedFilesDesc = null;
    } else {
      selectedFilesDesc = await FileSystemItemsStatus.validate(
        compute: () => Future.wait(
          selectedFiles.value!.map(FileDescriptor.fromHandle),
        ),
        items: selectedFiles.value!,
        mode: FileSystemPermissionMode.read,
      );
      notifyListeners();
    }
  }

  void computeSelectedFileForSaveDesc() async {
    if (selectedFileForSave.value == null) {
      selectedFileForSaveDesc = null;
    } else {
      selectedFileForSaveDesc = await FileSystemItemsStatus.validate(
        compute: () async {
          final v = await FileDescriptor.fromHandle(selectedFileForSave.value!);
          if (_editingFileTextLastValue == null) {
            _editingFileTextController.add(await v.file.readAsString());
          }
          return v;
        },
        items: [selectedFileForSave.value!],
        mode: FileSystemPermissionMode.readwrite,
      );
      notifyListeners();
    }
  }

  void computeSelectedDirectoryEntries() {
    if (selectedDirectory.value == null) {
      selectedDirectoryEntries = null;
    } else {
      selectedDirectoryEntries = selectedDirectory.value!
          .requestPermission(mode: FileSystemPermissionMode.read)
          .then((value) {
        final dir = selectedDirectory.value;
        if (value != PermissionStateEnum.granted || dir == null) {
          selectedDirectory.value = null;
          return [];
        }
        return dir.entries().toList();
      });
    }
  }

  static const _storeName = 'AppState';

  static FileSystemPersistance? persistance;

  void _setUpDB() async {
    try {
      persistance = await FileSystem.instance.getPersistance();

      final db = await idb.idbFactoryNative.open(
        'MainDB',
        version: 1,
        onUpgradeNeeded: (event) {
          event.database.createObjectStore(
            _storeName,
            keyPath: 'key',
            autoIncrement: false,
          );
        },
      );
      this.db = db;

      final tx = db.transaction(_storeName, idb.idbModeReadOnly);
      final objStore = tx.objectStore(_storeName);
      final values = await objStore.getAll();
      await tx.completed;

      print('fromJson json $values');
      if (values.isNotEmpty && values.first is Map) {
        final json = (values.first as Map).cast<String, Object?>();
        await populateFromJson(json);
      }

      addListener(_saveInStore);
    } catch (e, s) {
      print('_setUpDB $e $s');
    }
  }

  Future<bool> populateFromJson(Map<String, Object?> value) async {
    final Map<AppNotifier, Object?> toAssign = {};
    for (final n in allNotifiers) {
      final v = value[n.name];
      if (v == null) continue;

      final Object item;
      if (n.fromJson != null) {
        try {
          item = await n.fromJson!(v);
        } catch (e, s) {
          print('populateFromJson ${n.name} $e $s');
          return false;
        }
      } else {
        item = v;
      }
      if (n.canAssign(item)) {
        toAssign[n] = item;
      } else {
        print('!n.canAssign(item) ${n.name} item: $item');
        return false;
      }
    }
    toAssign.forEach((key, value) {
      key.value = value;
    });

    return true;
  }

  Timer? _saveInStoreTimer;

  Future<void> _saveInStore({bool throttle = true}) async {
    if (throttle) {
      _saveInStoreTimer ??= Timer(
        const Duration(seconds: 3),
        () async {
          await _saveInStore(throttle: false);
          _saveInStoreTimer = null;
        },
      );
      return;
    }

    final json = await toJson();
    final tx = db!.transaction(_storeName, idb.idbModeReadWrite);
    final objStore = tx.objectStore(_storeName);
    json['key'] = '0';
    await objStore.put(json);
    await tx.completed;
  }

  Future<Map<String, Object?>> toJson() async {
    return Map.fromIterables(
      allNotifiers.map((e) => e.name),
      await Future.wait(allNotifiers.map((e) async => e.toJson())),
      // final Object? v = e.value;
      // if (v is FileSystemDirectoryHandle) {
      //   return v.inner;
      // } else if (v is List<FileSystemDirectoryHandle>) {
      //   return v.map((e) => e.inner).toList();
      // }
      // return v;
      // }),
    );
  }

  late final List<AppNotifier> allNotifiers = [
    selectedDirectory,
    directoryStack,
    multiple,
    onlyImages,
    selectedFiles,
    selectedFileForSave,
    requestReadPermissions,
    requestWritePermissions,
  ];

  static Serde<T> serdeFile<T extends FileSystemHandle?>() {
    return Serde(
      fromJson: (inner) => FileSystem.instance
          .getPersistance()
          .then((p) => p.get(inner as int)?.value as T),
      toJson: (v) => v == null
          ? null
          : FileSystem.instance
              .getPersistance()
              .then((p) => p.put(v))
              .then((value) => value.id),
    );
  }

  final _errorsController = StreamController<String>.broadcast();
  Stream<String> get errorsStream => _errorsController.stream;

  final _editingFileTextController = StreamController<String>.broadcast();
  String? _editingFileTextLastValue;
  Stream<String> get editingFileTextStream => _editingFileTextController.stream;

  final selectedDirectory = AppNotifier<FileSystemDirectoryHandle?>.fromSerde(
    'selectedDirectory',
    null,
    serde: serdeFile<FileSystemDirectoryHandle?>(),
  );
  Future<List<FileSystemHandle>>? selectedDirectoryEntries;
  final directoryStack = AppNotifier<List<FileSystemDirectoryHandle>>.fromSerde(
    'directoryStack',
    [],
    serde: serdeFile<FileSystemDirectoryHandle>()
        .list<List<FileSystemDirectoryHandle>>(),
  );
  final multiple = AppNotifier<bool>('multiple', true);
  final onlyImages = AppNotifier<bool>('onlyImages', false);
  FileSystemItemsStatus<List<FileDescriptor>>? selectedFilesDesc;
  final selectedFiles = AppNotifier<List<FileSystemFileHandle>?>.fromSerde(
    'selectedFiles',
    null,
    serde:
        serdeFile<FileSystemFileHandle>().list<List<FileSystemFileHandle>?>(),
  );
  final selectedFileForSave = AppNotifier<FileSystemFileHandle?>.fromSerde(
    'selectedFileForSave',
    null,
    serde: serdeFile<FileSystemFileHandle?>(),
  );
  FileSystemItemsStatus<FileDescriptor>? selectedFileForSaveDesc;

  final requestReadPermissions =
      AppNotifier<bool>('requestReadPermissions', true);
  final requestWritePermissions =
      AppNotifier<bool>('requestWritePermissions', false);

  @override
  void dispose() {
    for (final n in allNotifiers) {
      n.removeListener(notifyListeners);
      n.dispose();
    }
    _errorsController.close();
    _editingFileTextController.close();
    removeListener(_saveInStore);
    super.dispose();
  }

  String resolve(FileSystemHandle handle) {
    // final dir = directoryStack.value.isEmpty
    //     ? selectedDirectory.value!
    //     : directoryStack.value.first;
    // return dir.resolve(possibleDescendant);
    return <FileSystemHandle>[
      ...directoryStack.value,
      selectedDirectory.value!,
      handle,
    ].map((e) => e.name).join('/');
  }

  void createItemInDirectory(String name, FileSystemHandleKind kind) async {
    final status = await selectedDirectory.value!.requestPermission(
      mode: FileSystemPermissionMode.readwrite,
    );

    if (status != PermissionStateEnum.granted) {
      _errorsController.add('Edit permission not granted');
      return;
    }

    final Result<FileSystemHandle, GetHandleError> handleResult;
    switch (kind) {
      case FileSystemHandleKind.directory:
        handleResult = await selectedDirectory.value!.getDirectoryHandle(
          name,
          create: true,
        );
        break;
      case FileSystemHandleKind.file:
        handleResult = await selectedDirectory.value!.getFileHandle(
          name,
          create: true,
        );
        break;
    }

    handleResult.when(
      ok: (ok) {
        notifyListeners();
      },
      err: (err) {
        _errorsController.add(err.toString());
      },
    );
  }

  void popDirectoryFromStack() {
    final copy = [...directoryStack.value];
    selectedDirectory.value = copy.removeLast();
    directoryStack.value = copy;
  }

  void viewInnerDirectory(FileSystemDirectoryHandle directory) {
    final copy = [...directoryStack.value, selectedDirectory.value!];
    directoryStack.value = copy;
    selectedDirectory.value = directory;
  }

  void selectDirectory() async {
    final directory = await FileSystem.instance.showDirectoryPicker();
    if (directory == null) {
      _errorsController.add('No directory selected');
    } else {
      selectedDirectory.value = directory;
    }
  }

  void selectFiles() async {
    final files = await FileSystem.instance.showOpenFilePicker(
      multiple: multiple.value,
      types: [
        if (onlyImages.value)
          const FilePickerAcceptType(
            description: 'Images',
            accept: {
              'image/*': ['.png', '.gif', '.jpeg', '.jpg']
            },
          )
      ],
    );
    if (files.isEmpty) {
      _errorsController.add('No files selected');
    } else {
      selectedFiles.value = files;
    }
  }

  void selectCurrentFile({required bool create}) async {
    final fileHandle = create
        ? await FileSystem.instance.showSaveFilePicker()
        : await FileSystem.instance.showOpenSingleFilePicker();
    if (fileHandle == null) {
      _errorsController.add('No file selected');
      return null;
    } else {
      selectFileForEdit(fileHandle, created: create);
    }
  }

  void saveFile(String text) async {
    try {
      final writable = await selectedFileForSave.value!.createWritable(
        keepExistingData: false,
      );
      await writable.write(FileSystemWriteChunkType.string(text));
      await writable.close();
      computeSelectedFileForSaveDesc();
      notifyListeners();
    } catch (e, s) {
      selectedFileForSave.value = null;
      _errorsController.add('Error saving file. $e $s');
    }
  }

  void selectFileForEdit(
    FileSystemFileHandle fileHandle, {
    bool created = false,
  }) async {
    final status = await fileHandle.requestPermission(
      mode: FileSystemPermissionMode.readwrite,
    );

    if (status != PermissionStateEnum.granted) {
      _errorsController.add('Write permission not granted');
    } else {
      try {
        if (!created) {
          final file = await fileHandle.getFile();
          final contentsStr = await file.readAsString();
          _editingFileTextController.add(contentsStr);
        }
        selectedFileForSave.value = fileHandle;
      } catch (e, s) {
        _errorsController.add('Error opening file. $e $s');
      }
    }
    return null;
  }

  void deleteItems(List<FileSystemHandle> handles) async {
    final status = await selectedDirectory.value!.requestPermission(
      mode: FileSystemPermissionMode.readwrite,
    );

    if (status != PermissionStateEnum.granted) {
      _errorsController.add('Edit permission not granted');
      return;
    }
    final results = await Future.wait(
      handles.map(
        (e) => selectedDirectory.value!.removeEntry(
          e.name,
          recursive: true,
        ),
      ),
    );
    final errors = results
        .map<RemoveEntryError?>((e) => e.errOrNull)
        .whereType<RemoveEntryError>()
        .toList();
    if (errors.isNotEmpty) {
      _errorsController.add(errors.join('\n'));
    }
    notifyListeners();
  }
}

typedef FromJsonFn<T> = FutureOr<T> Function(Object);
typedef ToJsonFn<T> = FutureOr<Object?> Function(T);

class AppNotifier<T> extends ValueNotifier<T> {
  final String name;
  final FromJsonFn<T>? fromJson;
  final ToJsonFn<T>? _toJson;

  FutureOr<Object?> toJson() => _toJson == null ? value : _toJson!(value);

  AppNotifier(
    this.name,
    T value, {
    this.fromJson,
    ToJsonFn<T>? toJson,
  })  : _toJson = toJson,
        super(value);

  AppNotifier.fromSerde(
    this.name,
    T value, {
    required Serde<T> serde,
  })  : fromJson = serde.fromJson,
        _toJson = serde.toJson,
        super(value);

  bool canAssign(dynamic object) => object is T;
}

class Serde<T> {
  final FromJsonFn<T>? fromJson;
  final ToJsonFn<T>? toJson;

  const Serde({
    this.fromJson,
    this.toJson,
  });

  Serde<L> list<L extends List<T>?>() {
    return Serde(
      fromJson: fromJson == null
          ? null
          : (v) => Future.wait(
                (v as List).map(
                  (e) async => (e == null ? null : fromJson!(e)) as FutureOr<T>,
                ),
              ) as Future<L>,
      toJson: toJson == null
          ? null
          : (v) => v == null
              ? null
              : Future.wait(
                  v.map((d) async => toJson!(d)),
                ),
    );
  }
}

class FileDescriptor {
  final String name;
  final String? mimeType;
  final DateTime lastModified;
  final int lengthInBytes;
  final FileSystemFileHandle handle;
  final XFile file;

  String get humanReadableBytes {
    final l = lengthInBytes;
    if (l < 1000) {
      return '$l bytes';
    } else if (l < 1e6) {
      return '${(l / 1000).toStringAsFixed(2)} kB';
    } else if (l < 1e9) {
      return '${(l / 1e6).toStringAsFixed(2)} MB';
    } else {
      return '${(l / 1e9).toStringAsFixed(2)} GB';
    }
  }

  FileDescriptor({
    required this.handle,
    required this.file,
    required this.lastModified,
    required this.name,
    required this.mimeType,
    required this.lengthInBytes,
  });

  static Future<FileDescriptor> fromHandle(FileSystemFileHandle handle) async {
    final file = await handle.getFile();

    return FileDescriptor(
      handle: handle,
      file: file,
      mimeType: file.mimeType,
      lastModified: await file.lastModified(),
      name: file.name,
      lengthInBytes: await file.length(),
    );
  }
}

class FileSystemCreateItemInfo {
  final String name;
  final FileSystemHandleKind kind;

  FileSystemCreateItemInfo({
    required this.name,
    required this.kind,
  });
}

class FileSystemItemsStatus<T> {
  final List<FileSystemHandle> items;
  final PermissionStateEnum permission;
  final T? value;
  final FileSystemPermissionMode mode;

  FileSystemItemsStatus({
    required this.mode,
    required this.items,
    required this.permission,
    this.value,
  });

  static Future<FileSystemItemsStatus<T>> validate<T>({
    required List<FileSystemHandle> items,
    required FileSystemPermissionMode mode,
    required FutureOr<T> Function() compute,
  }) async {
    final permissions = await Future.wait(
      items.map((e) => e.requestPermissionActivation(mode: mode)),
    );
    final denied = permissions
        .any((element) => element.okOrNull == PermissionStateEnum.denied);
    final prompt = permissions.any((element) =>
        element.isErr || element.okOrNull == PermissionStateEnum.prompt);
    final permission = denied
        ? PermissionStateEnum.denied
        : prompt
            ? PermissionStateEnum.prompt
            : PermissionStateEnum.granted;

    T? value;
    if (permission == PermissionStateEnum.granted) {
      value = await compute();
    }
    return FileSystemItemsStatus(
      items: items,
      mode: mode,
      permission: permission,
      value: value,
    );
  }
}
