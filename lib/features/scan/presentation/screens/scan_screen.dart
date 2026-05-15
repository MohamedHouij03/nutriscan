// lib/features/scan/presentation/screens/scan_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_utils.dart';
import '../providers/scan_notifier.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _imagePicker = ImagePicker();
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    // Reset scan state when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanNotifierProvider.notifier).reset();
    });
  }

  Future<void> _pickFromCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      AppUtils.showSnackBar(
        context,
        message: 'Camera permission required',
        isError: true,
      );
      return;
    }

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: (AppConstants.imageQuality * 100).toInt(),
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageFile = file;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppUtils.showSnackBar(
        context,
        message: 'Failed to open camera: $e',
        isError: true,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: (AppConstants.imageQuality * 100).toInt(),
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedImageFile = file;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppUtils.showSnackBar(
        context,
        message: 'Failed to open gallery: $e',
        isError: true,
      );
    }
  }

  Future<void> _startScan() async {
    if (_selectedImageBytes == null) {
      AppUtils.showSnackBar(
        context,
        message: 'Please select an image first',
        isError: true,
      );
      return;
    }

    await ref.read(scanNotifierProvider.notifier).startScan(
          _selectedImageBytes!,
          imagePath: _selectedImageFile?.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanNotifierProvider);

    // Navigate to result when done
    ref.listen(scanNotifierProvider, (prev, next) {
      if (next.isDone && next.result != null) {
        context.push(AppRoutes.result, extra: next.result);
      }
      if (next.hasError && next.failure != null) {
        AppUtils.showSnackBar(
          context,
          message: next.failure!.message,
          isError: true,
        );
        ref.read(scanNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ingredients'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: scanState.isLoading
          ? _buildLoadingView(scanState)
          : _buildScanView(context),
    );
  }

  Widget _buildScanView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image preview ─────────────────────────────────────────────
          _ImagePreview(
            imageBytes: _selectedImageBytes,
            onPickCamera: _pickFromCamera,
            onPickGallery: _pickFromGallery,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // ── Tips ──────────────────────────────────────────────────────
          _TipsCard().animate(delay: 100.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // ── Scan button ───────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _selectedImageBytes == null ? null : _startScan,
            icon: const Icon(Icons.search),
            label: const Text('Analyze Ingredients'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _selectedImageBytes == null
                  ? AppColors.textHint
                  : AppColors.primary,
            ),
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 12),

          // Secondary: pick new image
          if (_selectedImageBytes != null)
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImageFile = null;
                  _selectedImageBytes = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Choose Different Image'),
            ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildLoadingView(ScanState scanState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated scanner icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 50,
                color: AppColors.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1500.ms, color: AppColors.primaryLight),

            const SizedBox(height: 32),

            Text(
              scanState.progressMessage,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            const LinearProgressIndicator(
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            const SizedBox(height: 16),

            const Text(
              'Please wait while we analyze the ingredients for allergens and harmful additives.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const _ImagePreview({
    required this.imageBytes,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Preview container
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: imageBytes != null ? AppColors.primary : AppColors.divider,
              width: imageBytes != null ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Ready',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Select an ingredient list photo',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 16),

        // Pick buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.infoLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips for best results',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _tip('Good lighting — avoid shadows on the text'),
          _tip('Hold camera steady and close to the label'),
          _tip('Make sure all ingredient text is visible'),
          _tip('Works best with printed ingredient lists'),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.info)),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}
