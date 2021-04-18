import 'dart:typed_data';

import 'package:file_system_access/src/file_system_write_params.dart';

export 'package:file_system_access/src/file_system_write_params.dart';

abstract class FileSystemWriteChunkType {
  const FileSystemWriteChunkType._();

  const factory FileSystemWriteChunkType.bufferSource(
    ByteBuffer value,
  ) = _BufferSource;
  const factory FileSystemWriteChunkType.string(
    String value,
  ) = _String;
  const factory FileSystemWriteChunkType.writeParams(
    WriteParams value,
  ) = _WriteParams;

  dynamic get value;

  T when<T>({
    required T Function(ByteBuffer value) bufferSource,
    required T Function(String value) string,
    required T Function(WriteParams value) writeParams,
  }) {
    final FileSystemWriteChunkType v = this;
    if (v is _BufferSource) return bufferSource(v.value);
    if (v is _String) return string(v.value);
    if (v is _WriteParams) return writeParams(v.value);
    throw "";
  }

  T? maybeWhen<T>({
    T Function()? orElse,
    T Function(ByteBuffer value)? bufferSource,
    T Function(String value)? string,
    T Function(WriteParams value)? writeParams,
  }) {
    final FileSystemWriteChunkType v = this;
    if (v is _BufferSource)
      return bufferSource != null ? bufferSource(v.value) : orElse?.call();
    if (v is _String) return string != null ? string(v.value) : orElse?.call();
    if (v is _WriteParams)
      return writeParams != null ? writeParams(v.value) : orElse?.call();
    throw "";
  }

  T map<T>({
    required T Function(_BufferSource value) bufferSource,
    required T Function(_String value) string,
    required T Function(_WriteParams value) writeParams,
  }) {
    final FileSystemWriteChunkType v = this;
    if (v is _BufferSource) return bufferSource(v);
    if (v is _String) return string(v);
    if (v is _WriteParams) return writeParams(v);
    throw "";
  }

  T? maybeMap<T>({
    T Function()? orElse,
    T Function(_BufferSource value)? bufferSource,
    T Function(_String value)? string,
    T Function(_WriteParams value)? writeParams,
  }) {
    final FileSystemWriteChunkType v = this;
    if (v is _BufferSource)
      return bufferSource != null ? bufferSource(v) : orElse?.call();

    if (v is _String) return string != null ? string(v) : orElse?.call();
    if (v is _WriteParams)
      return writeParams != null ? writeParams(v) : orElse?.call();
    throw "";
  }
}

class _BufferSource extends FileSystemWriteChunkType {
  @override
  final ByteBuffer value;

  const _BufferSource(
    this.value,
  ) : super._();
}

class _String extends FileSystemWriteChunkType {
  @override
  final String value;

  const _String(
    this.value,
  ) : super._();
}

class _WriteParams extends FileSystemWriteChunkType {
  @override
  final WriteParams value;

  const _WriteParams(
    this.value,
  ) : super._();
}
