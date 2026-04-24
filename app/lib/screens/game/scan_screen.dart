import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/widgets.dart';
import '../../services/services.dart';

// Mobile-only imports
import 'package:camera/camera.dart'
    if (dart.library.html) '../../core/stubs/camera_stub.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final int partyId;
  final int roundId;
  final Function(int points, String? imagePath) onConfirm;

  const ScanScreen({
    super.key,
    required this.partyId,
    required this.roundId,
    required this.onConfirm,
  });

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _cameraController;
  List<DetectedCard> _detectedCards = [];
  bool _isProcessing = false;
  bool _cameraReady = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initCamera();
      ref.read(mlServiceProvider).loadModel();
    }
  }

  Future<void> _initCamera() async {
    if (kIsWeb) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) setState(() => _cameraReady = true);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndDetect() async {
    if (kIsWeb || _isProcessing || _cameraController == null) return;
    setState(() => _isProcessing = true);

    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        final cards = await ref.read(mlServiceProvider).detect(image);
        setState(() => _detectedCards = cards);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isProcessing = true);
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        final cards = kIsWeb
            ? <DetectedCard>[]
            : await ref.read(mlServiceProvider).detect(image);
        setState(() => _detectedCards = cards);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  int get _totalPoints =>
      _detectedCards.fold(0, (sum, card) => sum + card.points);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karten scannen'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Kamera Preview – nur auf Mobile
            if (!kIsWeb)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _cameraReady
                        ? Stack(
                            children: [
                              CameraPreview(_cameraController!),
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _captureAndDetect,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: _isProcessing
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            )
                                          : const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
              )
            else
              // Web: Info Text statt Kamera
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📷', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        'Kamera nicht verfügbar im Web',
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(color: AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bitte Punkte manuell eingeben',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ),

            // Galerie Button
            TextButton.icon(
              onPressed: _isProcessing ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Aus Galerie'),
            ),

            // Erkannte Karten
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erkannte Karten:',
                      style: AppTextStyles.titleMedium(context),
                    ),
                    const SizedBox(height: 8),
                    if (_detectedCards.isEmpty)
                      Text(
                        kIsWeb
                            ? 'Bitte Punkte manuell eingeben'
                            : 'Tippe auf den Auslöser um zu scannen',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textSecondaryDark),
                      )
                    else ...[
                      Expanded(
                        child: ListView.separated(
                          itemCount: _detectedCards.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final card = _detectedCards[index];
                            return Row(
                              children: [
                                UnoCardWidget(label: card.label),
                                const SizedBox(width: 12),
                                Text(
                                  card.symbol,
                                  style: AppTextStyles.bodyLarge(context),
                                ),
                                const Spacer(),
                                Text(
                                  '${card.points} Pkt.',
                                  style: AppTextStyles.bodyMedium(context)
                                      .copyWith(
                                        color: AppColors.textSecondaryDark,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: AppTextStyles.titleMedium(context),
                          ),
                          Text(
                            '$_totalPoints Pkt.',
                            style: AppTextStyles.titleMedium(
                              context,
                            ).copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: PrimaryButton(
                label: 'Bestätigen ✅',
                onPressed: _detectedCards.isEmpty
                    ? null
                    : () => widget.onConfirm(_totalPoints, null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
