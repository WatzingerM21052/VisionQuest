import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../app_routes.dart';
import '../services/auth_service.dart';
import '../services/vision_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _authService = AuthService();
  final _visionService = VisionService();

  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Keine Kamera verfuegbar.';
          _isInitializing = false;
        });
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Kamera konnte nicht gestartet werden.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _captureAndDetect() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getStoredToken();
      if (token == null) {
        throw VisionException('Nicht eingeloggt', code: 'NO_TOKEN');
      }

      final image = await _controller!.takePicture();
      final result = await _visionService.detectObject(
        image: image,
        token: token,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(
        context,
      ).pushNamed(AppRoutes.reward, arguments: result);
    } on VisionException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Erkennung fehlgeschlagen.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Chip(
                label: Text(
                  _isProcessing ? 'Erkennung läuft...' : 'Bereit',
                  style: theme.textTheme.labelSmall,
                ),
                avatar: Icon(
                  _isProcessing ? Icons.hourglass_bottom : Icons.check_circle,
                  size: 16,
                  color: _isProcessing
                      ? colorScheme.tertiary
                      : colorScheme.secondary,
                ),
                backgroundColor: _isProcessing
                    ? colorScheme.tertiaryContainer
                    : colorScheme.secondaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Camera Preview
            Expanded(
              child: Center(
                child: _buildPreview(theme),
              ),
            ),

            // Bottom Controls
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.error),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Main CTA Button
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _captureAndDetect,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      _isProcessing ? 'Erkennung läuft...' : 'Foto aufnehmen',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info Text
                  Text(
                    'Positioniere dein Objekt in der Bildmitte',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (_isInitializing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kamera wird initialisiert...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null && _controller == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Text(
        'Kamera nicht bereit.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.error,
        ),
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: CameraPreview(_controller!),
        ),
        // Crosshair overlay
        Positioned.fill(
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
