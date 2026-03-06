import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_routes.dart';
import '../models/achievement.dart';
import '../models/detection_focus_option.dart';
import '../models/detection_model_option.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';
import '../services/vision_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  final _visionService = VisionService();

  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;
  late Achievement _todayChallenge;
  int _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _selectTodayChallenge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// Initialisiert die Kamera mit Auto-Focus und Auto-Exposure.
  ///
  /// Setzt [_isInitializing] und [_errorMessage] basierend auf dem Ergebnis.
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
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}
      try {
        await controller.setExposureMode(ExposureMode.auto);
      } catch (_) {}

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

  /// Wählt eine zufällige Scanner-Quest aus allen Object-Scan Achievements.
  ///
  /// Setzt den Fortschritt zurück auf 0. Wird beim Start und nach Abschluss
  /// einer Quest aufgerufen.
  void _selectTodayChallenge() {
    final random = Random();
    final objectScanAchievements = allAchievements
        .where((a) => a.type == AchievementType.objectScan)
        .toList();

    if (objectScanAchievements.isEmpty) {
      return; // Fail-safe: keine scannable Achievements verfügbar
    }

    setState(() {
      _todayChallenge =
          objectScanAchievements[random.nextInt(objectScanAchievements.length)];
      _currentProgress = 0;
    });
  }

  /// Zeigt einen Erfolgs-Dialog an, wenn ein Achievement freigeschaltet wurde.
  void _showAchievementUnlock() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.primary.withAlpha((255 * 0.3).toInt()),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Achievement Icon with glow
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(
                          (255 * 0.4).toInt(),
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    _todayChallenge.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Achievement freigeschaltet!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Achievement Name
                Text(
                  _todayChallenge.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  _todayChallenge.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Rarity Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _todayChallenge.rarity.stars,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _todayChallenge.rarity.displayName.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close Button
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Weiter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Macht ein Foto und sendet es zur Objekterkennung an das Backend.
  ///
  /// Flow:
  /// 1. Check ob Kamera bereit ist
  /// 2. Hole Auth-Token
  /// 3. Mache Foto und sende zur Detection
  /// 4. Check ob Objekt zur aktuellen Quest passt
  /// 5. Update Quest-Fortschritt und entsperre Achievement bei Completion
  /// 6. Navigiere zum Reward Screen
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
      final appState = ref.read(appStateProvider);
      final result = await _visionService.detectObject(
        image: image,
        token: token,
        model: appState.detectionModel.apiValue,
        focus: appState.detectionFocus.apiValue,
      );

      if (!mounted) {
        return;
      }

      // Check if detected object matches today's challenge
      final isChallengeMatch =
          _todayChallenge.objectLabel != null &&
          result.label.toLowerCase().contains(
            _todayChallenge.objectLabel!.toLowerCase(),
          );

      if (isChallengeMatch) {
        setState(() {
          _currentProgress++;
        });

        // Check if quest is completed
        if (_currentProgress >= _todayChallenge.targetCount) {
          ref
              .read(appStateProvider.notifier)
              .unlockAchievement(_todayChallenge.id);
          _showAchievementUnlock();
          // Select new challenge after completing current one
          _selectTodayChallenge();
        }
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
    final detectionModel = ref.watch(
      appStateProvider.select((state) => state.detectionModel),
    );
    final detectionFocus = ref.watch(
      appStateProvider.select((state) => state.detectionFocus),
    );

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width > 1200
                ? 1000.0
                : (width > 900 ? 820.0 : 680.0);

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Column(
                        children: [
                          // Camera Preview
                          Expanded(child: Center(child: _buildPreview(theme))),
                        ],
                      ),
                    ),
                  ),
                ),

                // Today's Challenge Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_todayChallenge.icon} Scanne ${_todayChallenge.objectLabel ?? 'Objekte'} ($_currentProgress/${_todayChallenge.targetCount})',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Controls (full width)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: colorScheme.error),
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
                              _isProcessing
                                  ? 'Erkennung läuft...'
                                  : 'Scan starten',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tune,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${detectionModel.label} · ${detectionFocus.label}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Minimal Info Action (hover tooltip + expandable sheet)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Tooltip(
                              message: 'Erkennungstipps anzeigen',
                              child: IconButton(
                                onPressed: _showDetectionTips,
                                icon: const Icon(Icons.info_outline),
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                  backgroundColor: colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.8),
                                  foregroundColor: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDetectionTips() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erkennungstipps',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gut erkennbar: Person, Handy, Tasse, Flasche, Buch, Laptop, Stuhl, Rucksack.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Objekt mittig im Kreis, gute Beleuchtung, ruhige Hand.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
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
        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;
        final overlayDiameter = (shortestSide * 0.62).clamp(240.0, 380.0);

        return Stack(
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.12)),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: overlayDiameter,
                  height: overlayDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.88),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.28),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
