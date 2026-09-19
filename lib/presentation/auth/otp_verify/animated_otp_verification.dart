import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

enum OtpAnimationState {
  input,
  verifying,
  movingToCenter,
  orbiting,
  collapsing,
  success,
  error,
}

/// Native OTP boxes + success orbit/collapse/checkmark animation.
///
/// Digits / focus stay controlled by the parent (existing OTP logic).
class AnimatedOtpVerification extends StatefulWidget {
  const AnimatedOtpVerification({
    super.key,
    required this.length,
    required this.controllers,
    required this.focusNodes,
    required this.digits,
    required this.onChanged,
    required this.animationState,
    this.boxWidth = 48,
    this.boxHeight = 56,
    this.onSuccessAnimationComplete,
    this.onAnimationPhaseChanged,
  });

  final int length;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final List<String> digits;
  final void Function(int index, String value) onChanged;
  final OtpAnimationState animationState;
  final double boxWidth;
  final double boxHeight;
  final VoidCallback? onSuccessAnimationComplete;
  final ValueChanged<OtpAnimationState>? onAnimationPhaseChanged;

  @override
  State<AnimatedOtpVerification> createState() =>
      _AnimatedOtpVerificationState();
}

class _AnimatedOtpVerificationState extends State<AnimatedOtpVerification>
    with TickerProviderStateMixin {
  late final AnimationController _moveCtrl;
  late final AnimationController _orbitCtrl;
  late final AnimationController _collapseCtrl;
  late final AnimationController _successCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _pulseCtrl;

  OtpAnimationState? _running;
  bool _navScheduled = false;

  @override
  void initState() {
    super.initState();
    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _collapseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedOtpVerification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationState != widget.animationState) {
      _handleState(widget.animationState);
    }
  }

  Future<void> _handleState(OtpAnimationState state) async {
    if (state == OtpAnimationState.error) {
      await _shakeCtrl.forward(from: 0);
      _shakeCtrl.reset();
      return;
    }

    // Only kick off the sequence from the parent success signal.
    // Later phase syncs (orbiting/collapsing/success) must not re-trigger.
    if (state == OtpAnimationState.movingToCenter) {
      if (_running != null) return;
      await _playSuccessSequence();
    }
  }

  void _setPhase(OtpAnimationState phase) {
    _running = phase;
    widget.onAnimationPhaseChanged?.call(phase);
    if (mounted) setState(() {});
  }

  Future<void> _playSuccessSequence() async {
    _navScheduled = false;
    FocusScope.of(context).unfocus();
    _setPhase(OtpAnimationState.movingToCenter);

    await _moveCtrl.forward(from: 0);
    if (!mounted) return;

    _setPhase(OtpAnimationState.orbiting);
    await _orbitCtrl.forward(from: 0);
    if (!mounted) return;

    _setPhase(OtpAnimationState.collapsing);
    await _collapseCtrl.forward(from: 0);
    if (!mounted) return;

    _setPhase(OtpAnimationState.success);
    _pulseCtrl.repeat();
    await _successCtrl.forward(from: 0);
    if (!mounted) return;

    if (!_navScheduled) {
      _navScheduled = true;
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      widget.onSuccessAnimationComplete?.call();
    }
  }

  @override
  void dispose() {
    _moveCtrl.dispose();
    _orbitCtrl.dispose();
    _collapseCtrl.dispose();
    _successCtrl.dispose();
    _shakeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _animating =>
      widget.animationState == OtpAnimationState.movingToCenter ||
      widget.animationState == OtpAnimationState.orbiting ||
      widget.animationState == OtpAnimationState.collapsing ||
      widget.animationState == OtpAnimationState.success ||
      _running == OtpAnimationState.movingToCenter ||
      _running == OtpAnimationState.orbiting ||
      _running == OtpAnimationState.collapsing ||
      _running == OtpAnimationState.success;

  bool get _locked =>
      widget.animationState == OtpAnimationState.verifying || _animating;

  @override
  Widget build(BuildContext context) {
    final n = widget.length;
    final gap = 8.0;
    final totalW = n * widget.boxWidth + (n - 1) * gap;
    final stageH = math.max(widget.boxHeight + 24, 140.0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _moveCtrl,
        _orbitCtrl,
        _collapseCtrl,
        _successCtrl,
        _shakeCtrl,
        _pulseCtrl,
      ]),
      builder: (context, _) {
        final shakeT = Curves.easeOut.transform(_shakeCtrl.value);
        final shakeX = _shakeCtrl.isAnimating
            ? math.sin(shakeT * math.pi * 6) * 10 * (1 - shakeT)
            : 0.0;

        return SizedBox(
          height: stageH,
          width: double.infinity,
          child: Center(
            child: Transform.translate(
              offset: Offset(shakeX, 0),
              child: SizedBox(
                width: totalW,
                height: stageH,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (_running == OtpAnimationState.success ||
                        widget.animationState == OtpAnimationState.success)
                      RepaintBoundary(
                        child: _SuccessPulseRings(
                          progress: _pulseCtrl.value,
                          checkProgress: _successCtrl.value,
                          boxSize: widget.boxWidth * 0.72,
                        ),
                      ),
                    ...List.generate(n, (i) {
                      return _buildBox(i, n, totalW, gap, stageH);
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBox(int i, int n, double totalW, double gap, double stageH) {
    final startLeft = i * (widget.boxWidth + gap);
    final startTop = (stageH - widget.boxHeight) / 2;
    final centerX = totalW / 2 - widget.boxWidth / 2;
    final centerY = (stageH - widget.boxHeight) / 2;

    final moveT = Curves.easeInOutCubic.transform(_moveCtrl.value);
    final stagger = (i * 0.055).clamp(0.0, 0.35);
    final localMove = ((moveT - stagger) / (1 - stagger)).clamp(0.0, 1.0);

    final orbitT = Curves.easeInOut.transform(_orbitCtrl.value);
    final collapseT = Curves.easeInOutCubic.transform(_collapseCtrl.value);

    final orbitRadius = widget.boxWidth * 0.95 * (1 - collapseT);
    final baseAngle = -math.pi / 2 + (i * 2 * math.pi / n);
    final spin = orbitT * (math.pi * 1.35);
    final ox = math.cos(baseAngle + spin) * orbitRadius;
    final oy = math.sin(baseAngle + spin) * orbitRadius;

    double left = startLeft;
    double top = startTop;
    double scale = 1;
    double rot = 0;
    double digitOpacity = 1;
    Color borderColor;
    final filled = widget.digits[i].isNotEmpty;
    final focused = widget.focusNodes[i].hasFocus;
    final isError = widget.animationState == OtpAnimationState.error;

    if (isError) {
      borderColor = AppColors.danger;
    } else if (focused) {
      borderColor = const Color(0xFFF97316); // orange glow like reference
    } else if (filled) {
      borderColor = AppColors.primary;
    } else {
      borderColor = AppColors.gray200;
    }

    if (_moveCtrl.value > 0 || _orbitCtrl.value > 0 || _collapseCtrl.value > 0) {
      // Phase 1: row → center
      left = startLeft + (centerX - startLeft) * localMove;
      top = startTop + (centerY - startTop) * localMove;
      scale = 1.0 - 0.12 * localMove;

      if (_orbitCtrl.value > 0) {
        left = centerX + ox;
        top = centerY + oy;
        scale = 0.88 - 0.08 * orbitT;
        rot = spin * (i.isEven ? 1 : -0.65) * 0.35;
        digitOpacity = 1.0 - Curves.easeIn.transform(orbitT);
      }

      if (_collapseCtrl.value > 0) {
        left = centerX + ox * (1 - collapseT);
        top = centerY + oy * (1 - collapseT);
        scale = (0.8 - 0.35 * collapseT).clamp(0.35, 1.0);
        digitOpacity = 0;
        if (i == 0) {
          scale = 0.72 + 0.0 * collapseT;
          borderColor = Color.lerp(
                const Color(0xFFF97316),
                AppColors.success,
                collapseT,
              ) ??
              AppColors.success;
        } else {
          // fade outer boxes
          return Positioned(
            left: left,
            top: top,
            child: Opacity(
              opacity: (1 - collapseT).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: _OtpBoxFace(
                  width: widget.boxWidth,
                  height: widget.boxHeight,
                  digit: '',
                  digitOpacity: 0,
                  borderColor: borderColor,
                  showField: false,
                ),
              ),
            ),
          );
        }
      }

      if (_running == OtpAnimationState.success ||
          widget.animationState == OtpAnimationState.success) {
        if (i != 0) {
          return const SizedBox.shrink();
        }
        left = centerX;
        top = centerY;
        scale = 0.72;
        borderColor = AppColors.success;
        digitOpacity = 0;
      }
    }

    final showField = !_animating &&
        widget.animationState != OtpAnimationState.verifying;

    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: rot,
        child: Transform.scale(
          scale: scale,
          child: _OtpBoxFace(
            width: widget.boxWidth,
            height: widget.boxHeight,
            digit: widget.digits[i],
            digitOpacity: digitOpacity,
            borderColor: borderColor,
            glow: focused && !_locked && !isError,
            showField: showField,
            controller: widget.controllers[i],
            focusNode: widget.focusNodes[i],
            enabled: !_locked,
            showCheck: (_running == OtpAnimationState.success ||
                    widget.animationState == OtpAnimationState.success) &&
                i == 0,
            checkProgress: _successCtrl.value,
            onChanged: (v) => widget.onChanged(i, v),
          ),
        ),
      ),
    );
  }
}

class _OtpBoxFace extends StatelessWidget {
  const _OtpBoxFace({
    required this.width,
    required this.height,
    required this.digit,
    required this.digitOpacity,
    required this.borderColor,
    required this.showField,
    this.glow = false,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.showCheck = false,
    this.checkProgress = 0,
    this.onChanged,
  });

  final double width;
  final double height;
  final String digit;
  final double digitOpacity;
  final Color borderColor;
  final bool showField;
  final bool glow;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool showCheck;
  final double checkProgress;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: glow || showCheck ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: const Color(0xFFF97316).withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
          if (showCheck)
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: showCheck
          ? CustomPaint(
              size: Size(width * 0.42, height * 0.36),
              painter: _CheckPainter(
                progress: Curves.elasticOut
                    .transform(checkProgress.clamp(0.0, 1.0))
                    .clamp(0.0, 1.0),
                color: AppColors.success,
              ),
            )
          : showField
              ? TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: enabled,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray900.withValues(alpha: digitOpacity),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onChanged,
                )
              : Opacity(
                  opacity: digitOpacity,
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray900,
                    ),
                  ),
                ),
    );
  }
}

class _SuccessPulseRings extends StatelessWidget {
  const _SuccessPulseRings({
    required this.progress,
    required this.checkProgress,
    required this.boxSize,
  });

  final double progress;
  final double checkProgress;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boxSize * 4.2,
      height: boxSize * 4.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: boxSize * 2.4,
            height: boxSize * 2.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.18 * checkProgress),
                  AppColors.success.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          for (var r = 0; r < 3; r++)
            _ring(r, progress, boxSize),
        ],
      ),
    );
  }

  Widget _ring(int index, double t, double boxSize) {
    final phase = (t + index * 0.28) % 1.0;
    final scale = 0.55 + phase * 1.35;
    final opacity = (1 - phase) * 0.45;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: boxSize * 1.6,
        height: boxSize * 1.6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.success.withValues(alpha: opacity),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.55)
      ..lineTo(size.width * 0.40, size.height * 0.82)
      ..lineTo(size.width * 0.88, size.height * 0.18);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final extract = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
