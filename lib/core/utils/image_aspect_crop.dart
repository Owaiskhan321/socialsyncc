import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Shared aspect-ratio presets for create-post images.
enum MediaAspectRatioPreset {
  square(1, '1:1'),
  portrait45(4 / 5, '4:5');

  const MediaAspectRatioPreset(this.ratio, this.label);

  /// Width ÷ height.
  final double ratio;
  final String label;
}

/// Center-crops [file] to [aspectRatio] (width/height) and writes a JPEG temp file.
Future<File> cropImageFileToAspectRatio(
  File file,
  double aspectRatio,
) async {
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return file;

  final source = img.bakeOrientation(decoded);
  final w = source.width;
  final h = source.height;
  if (w <= 0 || h <= 0) return file;

  final target = aspectRatio <= 0 ? 1.0 : aspectRatio;
  final current = w / h;

  late int cropW;
  late int cropH;
  late int x;
  late int y;

  if ((current - target).abs() < 0.001) {
    return file;
  }

  if (current > target) {
    // Image is wider than target — crop sides.
    cropH = h;
    cropW = math.max(1, (h * target).round());
    x = math.max(0, ((w - cropW) / 2).round());
    y = 0;
  } else {
    // Image is taller — crop top/bottom.
    cropW = w;
    cropH = math.max(1, (w / target).round());
    x = 0;
    y = math.max(0, ((h - cropH) / 2).round());
  }

  cropW = math.min(cropW, w - x);
  cropH = math.min(cropH, h - y);

  final cropped = img.copyCrop(
    source,
    x: x,
    y: y,
    width: cropW,
    height: cropH,
  );

  final outBytes = img.encodeJpg(cropped, quality: 92);
  final name =
      'ss_crop_${DateTime.now().microsecondsSinceEpoch}_${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'img'}.jpg';
  final out = File('${Directory.systemTemp.path}${Platform.pathSeparator}$name');
  await out.writeAsBytes(outBytes, flush: true);
  return out;
}

Future<List<File>> cropImageFilesToAspectRatio(
  List<File> files,
  double aspectRatio,
) async {
  final out = <File>[];
  for (final f in files) {
    out.add(await cropImageFileToAspectRatio(f, aspectRatio));
  }
  return out;
}

Future<File> writeCroppedBytesToTempFile(Uint8List bytes) async {
  final name = 'ss_manual_crop_${DateTime.now().microsecondsSinceEpoch}.jpg';
  final out = File('${Directory.systemTemp.path}${Platform.pathSeparator}$name');
  await out.writeAsBytes(bytes, flush: true);
  return out;
}
