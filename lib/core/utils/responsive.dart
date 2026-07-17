import 'package:flutter/material.dart';

/// Responsive helpers for smooth layouts on every mobile size.
class R {
  R._(this._size);

  factory R.of(BuildContext context) => R._(MediaQuery.sizeOf(context));

  final Size _size;

  double get width => _size.width;
  double get height => _size.height;

  /// Scale based on design width 393 (iPhone 14 Pro)
  double sw(double value) => value * (width / 393).clamp(0.85, 1.25);

  /// Scale based on design height 852
  double sh(double value) => value * (height / 852).clamp(0.85, 1.2);

  double sp(double value) => value * (width / 393).clamp(0.88, 1.15);

  EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: sw(20));

  bool get isSmall => width < 360;
  bool get isLarge => width >= 420;
}
