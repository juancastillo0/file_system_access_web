import 'package:file_system_access/src/models/write_chunk_type.dart';

abstract class WriteParams {
  const WriteParams._();

  const factory WriteParams.write({
    required WriteChunkType data,
    int? position,
  }) = WriteParamsWrite;
  const factory WriteParams.seek({
    required int position,
  }) = WriteParamsSeek;
  const factory WriteParams.truncate({
    required int size,
  }) = WriteParamsTruncate;

  T when<T>({
    required T Function(WriteChunkType data, int? position) write,
    required T Function(int position) seek,
    required T Function(int size) truncate,
  }) {
    final WriteParams v = this;
    if (v is WriteParamsWrite) return write(v.data, v.position);
    if (v is WriteParamsSeek) return seek(v.position);
    if (v is WriteParamsTruncate) return truncate(v.size);
    throw '';
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function(WriteChunkType data, int? position)? write,
    T Function(int position)? seek,
    T Function(int size)? truncate,
  }) {
    final WriteParams v = this;
    if (v is WriteParamsWrite) {
      return write != null ? write(v.data, v.position) : orElse.call();
    } else if (v is WriteParamsSeek) {
      return seek != null ? seek(v.position) : orElse.call();
    } else if (v is WriteParamsTruncate) {
      return truncate != null ? truncate(v.size) : orElse.call();
    }
    throw '';
  }

  T map<T>({
    required T Function(WriteParamsWrite value) write,
    required T Function(WriteParamsSeek value) seek,
    required T Function(WriteParamsTruncate value) truncate,
  }) {
    final WriteParams v = this;
    if (v is WriteParamsWrite) return write(v);
    if (v is WriteParamsSeek) return seek(v);
    if (v is WriteParamsTruncate) return truncate(v);
    throw '';
  }

  T maybeMap<T>({
    required T Function() orElse,
    T Function(WriteParamsWrite value)? write,
    T Function(WriteParamsSeek value)? seek,
    T Function(WriteParamsTruncate value)? truncate,
  }) {
    final WriteParams v = this;
    if (v is WriteParamsWrite) {
      return write != null ? write(v) : orElse.call();
    } else if (v is WriteParamsSeek) {
      return seek != null ? seek(v) : orElse.call();
    } else if (v is WriteParamsTruncate) {
      return truncate != null ? truncate(v) : orElse.call();
    }
    throw '';
  }
//   static WriteParams fromJson(Map<String, dynamic> map) {
//   switch (map["runtimeType"] as String) {
//     case '_Write': return _Write.fromJson(map);
//     case '_Seek': return _Seek.fromJson(map);
//     case '_Truncate': return _Truncate.fromJson(map);
//     default:
//       return null;
//   }
// }

  Map<String, dynamic> toJson();
}

class WriteParamsWrite extends WriteParams {
  final int? position;
  final WriteChunkType data;

  const WriteParamsWrite({
    required this.data,
    this.position,
  }) : super._();

  // static _Write fromJson(Map<String, dynamic> map) {
  //   return _Write(
  //     data: dynamic.fromJson(map['data'] as Map<String, dynamic>),
  //     position: map['position'] as int,
  //   );
  // }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'write',
      'position': position,
      'data': data.value,
    };
  }
}

class WriteParamsSeek extends WriteParams {
  final int position;

  const WriteParamsSeek({
    required this.position,
  }) : super._();

  // static _Seek fromJson(Map<String, dynamic> map) {
  //   return _Seek(
  //     position: map['position'] as int,
  //   );
  // }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'seek',
      'position': position,
    };
  }
}

class WriteParamsTruncate extends WriteParams {
  final int size;

  const WriteParamsTruncate({
    required this.size,
  }) : super._();

  // static _Truncate fromJson(Map<String, dynamic> map) {
  //   return _Truncate(
  //     size: map['size'] as int,
  //   );
  // }

  @override
  Map<String, Object?> toJson() {
    return {
      'type': 'truncate',
      'size': size,
    };
  }
}
