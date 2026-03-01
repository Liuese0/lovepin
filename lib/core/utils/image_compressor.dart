import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageCompressor {
  ImageCompressor._();

  static const Uuid _uuid = Uuid();

  /// Compresses an image file to a maximum dimension of 1024px with quality 80.
  ///
  /// Returns a new [File] containing the compressed image. The original file
  /// is not modified.
  static Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/compressed_${_uuid.v4()}.jpg';

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 1024,
      minHeight: 1024,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }

  /// Generates a small thumbnail from an image file.
  ///
  /// Compresses to a maximum dimension of 200px with quality 60.
  /// Returns a new [File] containing the thumbnail. The original file
  /// is not modified.
  static Future<File> generateThumbnail(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/thumb_${_uuid.v4()}.jpg';

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 200,
      minHeight: 200,
      quality: 60,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Thumbnail generation failed');
    }

    return File(result.path);
  }

  /// Compresses image data (bytes) directly and returns compressed bytes.
  ///
  /// Useful when you already have the image data in memory.
  static Future<List<int>> compressImageBytes(List<int> imageBytes) async {
    final result = await FlutterImageCompress.compressWithList(
      imageBytes is Uint8List ? imageBytes : Uint8List.fromList(imageBytes),
      minWidth: 1024,
      minHeight: 1024,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    return result;
  }
}