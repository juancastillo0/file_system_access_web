import 'package:file_system_access/src/file_system_access_interface.dart';
import 'package:file_system_access/src/utils.dart';
import 'package:meta/meta.dart';

mixin FsOptionsBase {
  String? get id;
  FsOptionsStartsIn? get startIn;
}

abstract class WellKnownDirectory {
  const WellKnownDirectory._();

  static const desktop = 'desktop';
  static const documents = 'documents';
  static const downloads = 'downloads';
  static const music = 'music';
  static const pictures = 'pictures';
  static const videos = 'videos';
}

@immutable
class FsOptionsStartsIn {
  /// Could be one of [WellKnownDirectory] for WEB.
  final String? path;
  final FileSystemHandle? handle;

  const FsOptionsStartsIn.path(
    String this.path,
  ) : handle = null;

  const FsOptionsStartsIn.handle(
    FileSystemHandle this.handle,
  ) : path = null;

  @override
  String toString() {
    return 'FsOptionsStartsIn(path: $path, handle: $handle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FsOptionsStartsIn &&
        other.path == path &&
        other.handle == handle;
  }

  @override
  int get hashCode {
    return path.hashCode ^ handle.hashCode;
  }
}

mixin FsPicketOptionsBase implements FsOptionsBase {
  @override
  String? get id;
  @override
  FsOptionsStartsIn? get startIn;
  List<FilePickerAcceptType> get types;
  bool get excludeAcceptAllOption;
}

@immutable
class FsOpenOptions with FsPicketOptionsBase {
  @override
  final List<FilePickerAcceptType> types;
  @override
  final bool excludeAcceptAllOption;
  @override
  final String? id;
  @override
  final FsOptionsStartsIn? startIn;

  final bool multiple;

  const FsOpenOptions({
    this.types = const [],
    this.excludeAcceptAllOption = false,
    this.id,
    this.startIn,
    this.multiple = true,
  });

  FsOpenOptions copyWith({
    List<FilePickerAcceptType>? types,
    bool? excludeAcceptAllOption,
    String? id,
    FsOptionsStartsIn? startIn,
    bool? multiple,
  }) {
    return FsOpenOptions(
      types: types ?? this.types,
      excludeAcceptAllOption:
          excludeAcceptAllOption ?? this.excludeAcceptAllOption,
      id: id ?? this.id,
      startIn: startIn ?? this.startIn,
      multiple: multiple ?? this.multiple,
    );
  }

  @override
  String toString() {
    return 'FsOpenOptions(types: $types, excludeAcceptAllOption:'
        ' $excludeAcceptAllOption, id: $id, startIn: $startIn,'
        ' multiple: $multiple)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FsOpenOptions &&
        listEquals(other.types, types) &&
        other.excludeAcceptAllOption == excludeAcceptAllOption &&
        other.id == id &&
        other.startIn == startIn &&
        other.multiple == multiple;
  }

  @override
  int get hashCode {
    return Object.hashAll(types) ^
        excludeAcceptAllOption.hashCode ^
        id.hashCode ^
        startIn.hashCode ^
        multiple.hashCode;
  }
}

@immutable
class FsSaveOptions with FsPicketOptionsBase {
  @override
  final List<FilePickerAcceptType> types;
  @override
  final bool excludeAcceptAllOption;
  @override
  final String? id;
  @override
  final FsOptionsStartsIn? startIn;

  final String? suggestedName;

  const FsSaveOptions({
    this.types = const [],
    this.excludeAcceptAllOption = false,
    this.id,
    this.startIn,
    this.suggestedName,
  });

  FsSaveOptions copyWith({
    List<FilePickerAcceptType>? types,
    bool? excludeAcceptAllOption,
    String? id,
    FsOptionsStartsIn? startIn,
    String? suggestedName,
  }) {
    return FsSaveOptions(
      types: types ?? this.types,
      excludeAcceptAllOption:
          excludeAcceptAllOption ?? this.excludeAcceptAllOption,
      id: id ?? this.id,
      startIn: startIn ?? this.startIn,
      suggestedName: suggestedName ?? this.suggestedName,
    );
  }

  @override
  String toString() {
    return 'FsSaveOptions(types: $types, excludeAcceptAllOption:'
        ' $excludeAcceptAllOption, id: $id, startIn: $startIn,'
        ' suggestedName: $suggestedName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FsSaveOptions &&
        listEquals(other.types, types) &&
        other.excludeAcceptAllOption == excludeAcceptAllOption &&
        other.id == id &&
        other.startIn == startIn &&
        other.suggestedName == suggestedName;
  }

  @override
  int get hashCode {
    return Object.hashAll(types) ^
        excludeAcceptAllOption.hashCode ^
        id.hashCode ^
        startIn.hashCode ^
        suggestedName.hashCode;
  }
}

@immutable
class FsDirectoryOptions with FsOptionsBase {
  @override
  final String? id;
  @override
  final FsOptionsStartsIn? startIn;

  final FileSystemPermissionMode mode;

  const FsDirectoryOptions({
    this.id,
    this.startIn,
    this.mode = FileSystemPermissionMode.read,
  });

  FsDirectoryOptions copyWith({
    String? id,
    FsOptionsStartsIn? startIn,
    FileSystemPermissionMode? mode,
  }) {
    return FsDirectoryOptions(
      id: id ?? this.id,
      startIn: startIn ?? this.startIn,
      mode: mode ?? this.mode,
    );
  }

  @override
  String toString() =>
      'FsDirectoryOptions(id: $id, startIn: $startIn, mode: $mode)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FsDirectoryOptions &&
        other.id == id &&
        other.startIn == startIn &&
        other.mode == mode;
  }

  @override
  int get hashCode => id.hashCode ^ startIn.hashCode ^ mode.hashCode;
}
