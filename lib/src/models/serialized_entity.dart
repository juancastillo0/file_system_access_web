import 'dart:ui';

import 'package:file_system_access/file_system_access.dart';
import 'package:flutter/foundation.dart';

abstract class SerializedFileEntity {
  const SerializedFileEntity._();

  const factory SerializedFileEntity.directory({
    required String name,
    required List<SerializedFileEntity> entities,
  }) = SerializedDirectory;
  const factory SerializedFileEntity.file({
    required String name,
    required String content,
  }) = SerializedFile;

  String get name;

  _T when<_T>({
    required _T Function(String name, List<SerializedFileEntity> entities)
        directory,
    required _T Function(String name, String content) file,
  }) {
    final v = this;
    if (v is SerializedDirectory) {
      return directory(v.name, v.entities);
    } else if (v is SerializedFile) {
      return file(v.name, v.content);
    }
    throw Exception();
  }

  _T maybeWhen<_T>({
    required _T Function() orElse,
    _T Function(String name, List<SerializedFileEntity> entities)? directory,
    _T Function(String name, String content)? file,
  }) {
    final v = this;
    if (v is SerializedDirectory) {
      return directory != null ? directory(v.name, v.entities) : orElse.call();
    } else if (v is SerializedFile) {
      return file != null ? file(v.name, v.content) : orElse.call();
    }
    throw Exception();
  }

  _T map<_T>({
    required _T Function(SerializedDirectory value) directory,
    required _T Function(SerializedFile value) file,
  }) {
    final v = this;
    if (v is SerializedDirectory) {
      return directory(v);
    } else if (v is SerializedFile) {
      return file(v);
    }
    throw Exception();
  }

  _T maybeMap<_T>({
    required _T Function() orElse,
    _T Function(SerializedDirectory value)? directory,
    _T Function(SerializedFile value)? file,
  }) {
    final v = this;
    if (v is SerializedDirectory) {
      return directory != null ? directory(v) : orElse.call();
    } else if (v is SerializedFile) {
      return file != null ? file(v) : orElse.call();
    }
    throw Exception();
  }

  bool get isSerializedDirectory => this is SerializedDirectory;
  bool get isSerializedFile => this is SerializedFile;

  TypeSerializedFileEntity get typeEnum;

  static SerializedFileEntity fromJson(Map<String, dynamic> map) {
    switch (map["runtimeType"] as String) {
      case "directory":
        return SerializedDirectory.fromJson(map);
      case "file":
        return SerializedFile.fromJson(map);
      default:
        throw Exception(
            'Invalid discriminator for SerializedFileEntity.fromJson ${map["runtimeType"]}. Input map: $map');
    }
  }

  Map<String, dynamic> toJson();
}

enum TypeSerializedFileEntity {
  directory,
  file,
}

TypeSerializedFileEntity? parseTypeSerializedFileEntity(String rawString,
    {bool caseSensitive = true}) {
  final _rawString = caseSensitive ? rawString : rawString.toLowerCase();
  for (final variant in TypeSerializedFileEntity.values) {
    final variantString = caseSensitive
        ? variant.toEnumString()
        : variant.toEnumString().toLowerCase();
    if (_rawString == variantString) {
      return variant;
    }
  }
  return null;
}

extension TypeSerializedFileEntityExtension on TypeSerializedFileEntity {
  String toEnumString() => toString().split(".")[1];
  String enumType() => toString().split(".")[0];

  bool get isSerializedDirectory => this == TypeSerializedFileEntity.directory;
  bool get isSerializedFile => this == TypeSerializedFileEntity.file;

  _T when<_T>({
    required _T Function() directory,
    required _T Function() file,
  }) {
    switch (this) {
      case TypeSerializedFileEntity.directory:
        return directory();
      case TypeSerializedFileEntity.file:
        return file();
    }
  }

  _T maybeWhen<_T>({
    _T Function()? directory,
    _T Function()? file,
    required _T Function() orElse,
  }) {
    _T Function()? c;
    switch (this) {
      case TypeSerializedFileEntity.directory:
        c = directory;
        break;
      case TypeSerializedFileEntity.file:
        c = file;
        break;
    }
    return (c ?? orElse).call();
  }
}

class SerializedDirectory extends SerializedFileEntity {
  final String name;
  final List<SerializedFileEntity> entities;

  const SerializedDirectory({
    required this.name,
    required this.entities,
  }) : super._();

  static Future<SerializedDirectory> fromHandle(
    FileSystemDirectoryHandle dir,
  ) async {
    final entries = await dir.entries().asyncMap((handle) {
      if (handle is FileSystemFileHandle) {
        return SerializedFile.fromHandle(handle);
      } else {
        final dir = (handle as FileSystemDirectoryHandle);
        return fromHandle(dir);
      }
    }).toList();

    return SerializedDirectory(
      entities: entries,
      name: dir.name,
    );
  }

  @override
  TypeSerializedFileEntity get typeEnum => TypeSerializedFileEntity.directory;

  static SerializedDirectory fromJson(Map<String, dynamic> map) {
    return SerializedDirectory(
      name: map['name'] as String,
      entities: (map['entities'] as List)
          .map((e) => SerializedFileEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "runtimeType": "directory",
      "name": name,
      "entities": entities.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializedDirectory &&
        other.name == name &&
        listEquals(other.entities, entities);
  }

  @override
  int get hashCode => hashValues(name, entities.hashCode);
}

class SerializedFile extends SerializedFileEntity {
  final String name;
  final String content;

  const SerializedFile({
    required this.name,
    required this.content,
  }) : super._();

  @override
  TypeSerializedFileEntity get typeEnum => TypeSerializedFileEntity.file;

  static Future<SerializedFile> fromHandle(FileSystemFileHandle handle) async {
    final file = await handle.getFile();
    final content = await file.readAsString();
    return SerializedFile(
      content: content,
      name: file.name,
    );
  }

  static SerializedFile fromJson(Map<String, dynamic> map) {
    return SerializedFile(
      name: map['name'] as String,
      content: map['content'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "runtimeType": "file",
      "name": name,
      "content": content,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SerializedFile &&
        other.name == name &&
        other.content == content;
  }

  @override
  int get hashCode => hashValues(name, content);
}
