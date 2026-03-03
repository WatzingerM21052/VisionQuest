import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../providers/app_state_provider.dart';
import '../services/vision_service.dart';

class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key, required this.result});

  final VisionResult result;

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = true;
  bool _questResultStored = false;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  int get _xpReward {
    final value = (widget.result.confidence * 100).round();
    if (value < 10) return 10;
    return value;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _startAnalysisPhase();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysisPhase() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));

    if (!mounted) {
      return;
    }

    setState(() {
      _isAnalyzing = false;
    });

    if (!_questResultStored) {
      ref
          .read(appStateProvider.notifier)
          .addQuestResult(
            label: widget.result.label,
            confidence: widget.result.confidence,
          );
      _questResultStored = true;
    }

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: !_isAnalyzing,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quest Analyse'),
          automaticallyImplyLeading: !_isAnalyzing,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final contentWidth = width > 1000
                  ? 760.0
                  : (width > 700 ? 620.0 : 480.0);

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isAnalyzing
                          ? _buildAnalyzingState(theme, colorScheme)
                          : _buildRewardState(theme, colorScheme),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingState(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        key: const ValueKey('analyzing'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie Loading Animation
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Lottie.network(
              'https://assets.lottiefiles.com/packages/lf20_jcikwtux.json',
              fit: BoxFit.contain,
              onLoaded: (composition) {
                // Animation loaded successfully
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback to circular progress indicator
                return CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Analysiere...',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dein Fund wird gerade geprüft',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 40,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                backgroundColor: colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardState(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        key: const ValueKey('reward'),
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie Success Animation with Scale
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.2),
                    colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                ),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.92, end: 1.0),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Icon(
                  Icons.workspace_premium,
                  size: 120,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Success Message
          Text(
            'Quest geschafft!',
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Recognized Object
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✓ ${widget.result.label.toUpperCase()}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // XP Reward Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Erfahrung verdient',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$_xpReward XP',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Erkennungsgenauigkeit: ${(widget.result.confidence * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Continue Button
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle),
            label: const Text('Weiter zum Scanning'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
