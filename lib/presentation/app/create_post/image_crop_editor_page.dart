import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_aspect_crop.dart';
import '../../../core/widgets/app_button.dart';

/// Interactive crop editor — fixed [aspectRatio], user pans/zooms the image.
class ImageCropEditorPage extends StatefulWidget {
  const ImageCropEditorPage({
    super.key,
    required this.sourceFile,
    required this.aspectRatio,
    required this.ratioLabel,
  });

  final File sourceFile;
  final double aspectRatio;
  final String ratioLabel;

  @override
  State<ImageCropEditorPage> createState() => _ImageCropEditorPageState();
}

Future<File?> openImageCropEditor(
  BuildContext context, {
  required File sourceFile,
  required double aspectRatio,
  required String ratioLabel,
}) {
  return Navigator.of(context).push<File>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ImageCropEditorPage(
        sourceFile: sourceFile,
        aspectRatio: aspectRatio,
        ratioLabel: ratioLabel,
      ),
    ),
  );
}

class _ImageCropEditorPageState extends State<ImageCropEditorPage> {
  final _controller = CropController();
  Uint8List? _imageBytes;
  var _loading = true;
  var _cropping = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.sourceFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load image.';
      });
    }
  }

  void _onSave() {
    if (_cropping || _imageBytes == null) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  Future<void> _onCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          final file = await writeCroppedBytesToTempFile(croppedImage);
          if (!mounted) return;
          Navigator.of(context).pop(file);
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _cropping = false;
            _error = 'Could not save crop.';
          });
        }
      case CropFailure(:final cause):
        if (!mounted) return;
        setState(() {
          _cropping = false;
          _error = 'Crop failed: $cause';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray900,
      appBar: AppBar(
        backgroundColor: AppColors.gray900,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Crop · ${widget.ratioLabel}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Drag and pinch to choose the part of the photo you want to keep.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.white),
                          ),
                        ),
                      )
                    : _imageBytes == null
                        ? const SizedBox.shrink()
                        : Crop(
                            image: _imageBytes!,
                            controller: _controller,
                            aspectRatio: widget.aspectRatio,
                            interactive: true,
                            fixCropRect: true,
                            baseColor: AppColors.gray900,
                            maskColor: AppColors.black.withValues(alpha: 0.55),
                            radius: 4,
                            cornerDotBuilder: (_, _) => const SizedBox.shrink(),
                            onCropped: _onCropped,
                          ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.gray100)),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: _cropping ? 'Saving…' : 'Apply crop',
                loading: _cropping,
                onPressed: _cropping || _imageBytes == null ? null : _onSave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
