import 'dart:async';

import 'package:flutter/material.dart';

import '../services/vision_service.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key, required this.result});

  final VisionResult result;

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = true;
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

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Quest Analyse')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isAnalyzing
                  ? _buildAnalyzingState(theme)
                  : _buildRewardState(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingState(ThemeData theme) {
    return Column(
      key: const ValueKey('analyzing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(strokeWidth: 6),
        ),
        const SizedBox(height: 24),
        Text('Analysiere...', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Dein Fund wird geprüft.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRewardState(ThemeData theme) {
    return Column(
      key: const ValueKey('reward'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            Icons.workspace_premium,
            size: 108,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text('Quest geschafft!', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Erkannt: ${widget.result.label}',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '+$_xpReward XP',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sicherheit: ${(widget.result.confidence * 100).toStringAsFixed(1)}%',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Weiter'),
        ),
      ],
    );
  }
}
