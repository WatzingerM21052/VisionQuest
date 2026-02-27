import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
  VisionResult? _result;

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
      _result = null;
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

      setState(() {
        _result = result;
      });
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

    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Center(child: _buildPreview(theme))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_result != null)
                    Text(
                      'Erkannt: ${_result!.label}\n'
                      'Sicherheit: ${(_result!.confidence * 100).toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _captureAndDetect,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_isProcessing ? 'Erkennung...' : 'Scannen'),
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
    if (_isInitializing) {
      return const CircularProgressIndicator();
    }

    if (_errorMessage != null && _controller == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Text('Kamera nicht bereit.');
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    );
  }
}
