import 'dart:typed_data';

import 'package:file_system_access/src/models/write_params.dart';

export 'package:file_system_access/src/models/write_params.dart';

abstract class WriteChunkType {
  const WriteChunkType._();

  const factory WriteChunkType.bufferSource(
    ByteBuffer value,
  ) = WriteChunkTypeBufferSource;
  const factory WriteChunkType.string(
    String value,
  ) = WriteChunkTypeString;
  const factory WriteChunkType.writeParams(
    WriteParams value,
  ) = WriteChunkTypeWriteParams;

  Object get value;

  T when<T>({
    required T Function(ByteBuffer value) bufferSource,
    required T Function(String value) string,
    required T Function(WriteParams value) writeParams,
  }) {
    final WriteChunkType v = this;
    if (v is WriteChunkTypeBufferSource) return bufferSource(v.value);
    if (v is WriteChunkTypeString) return string(v.value);
    if (v is WriteChunkTypeWriteParams) return writeParams(v.value);
    throw '';
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function(ByteBuffer value)? bufferSource,
    T Function(String value)? string,
    T Function(WriteParams value)? writeParams,
  }) {
    final WriteChunkType v = this;
    if (v is WriteChunkTypeBufferSource) {
      return bufferSource != null ? bufferSource(v.value) : orElse.call();
    } else if (v is WriteChunkTypeString) {
      return string != null ? string(v.value) : orElse.call();
    } else if (v is WriteChunkTypeWriteParams) {
      return writeParams != null ? writeParams(v.value) : orElse.call();
    }
    throw '';
  }

  T map<T>({
    required T Function(WriteChunkTypeBufferSource value) bufferSource,
    required T Function(WriteChunkTypeString value) string,
    required T Function(WriteChunkTypeWriteParams value) writeParams,
  }) {
    final WriteChunkType v = this;
    if (v is WriteChunkTypeBufferSource) return bufferSource(v);
    if (v is WriteChunkTypeString) return string(v);
    if (v is WriteChunkTypeWriteParams) return writeParams(v);
    throw '';
  }

  T maybeMap<T>({
    required T Function() orElse,
    T Function(WriteChunkTypeBufferSource value)? bufferSource,
    T Function(WriteChunkTypeString value)? string,
    T Function(WriteChunkTypeWriteParams value)? writeParams,
  }) {
    final WriteChunkType v = this;
    if (v is WriteChunkTypeBufferSource) {
      return bufferSource != null ? bufferSource(v) : orElse.call();
    } else if (v is WriteChunkTypeString) {
      return string != null ? string(v) : orElse.call();
    } else if (v is WriteChunkTypeWriteParams) {
      return writeParams != null ? writeParams(v) : orElse.call();
    }
    throw '';
  }
}

class WriteChunkTypeBufferSource extends WriteChunkType {
  @override
  final ByteBuffer value;

  const WriteChunkTypeBufferSource(
    this.value,
  ) : super._();
}

class WriteChunkTypeString extends WriteChunkType {
  @override
  final String value;

  const WriteChunkTypeString(
    this.value,
  ) : super._();
}

class WriteChunkTypeWriteParams extends WriteChunkType {
  @override
  final WriteParams value;

  const WriteChunkTypeWriteParams(
    this.value,
  ) : super._();
}
