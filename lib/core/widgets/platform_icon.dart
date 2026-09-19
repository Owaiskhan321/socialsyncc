import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'social_logos.dart';

/// Official-style brand mark for each connected social platform.
class PlatformIcon extends StatelessWidget {
  const PlatformIcon({
    super.key,
    required this.id,
    this.size = 24,
    this.withBackground = true,
  });

  final String id;
  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final key = id.toLowerCase();
    if (key == 'google' || key == 'google_business') {
      return _boxed(
        background: const Color(0xFFF1F5F9),
        child: GoogleLogo(size: size * 0.55),
      );
    }

    if (key == 'snapchat' || key == 'snap') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/snapchat_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _boxed(
            background: const Color(0xFFFFFC00),
            child: FaIcon(
              FontAwesomeIcons.snapchat,
              size: size * 0.48,
              color: Colors.black,
            ),
          ),
        ),
      );
    }

    final brand = _brandFor(key);
    if (brand == null) return SizedBox(width: size, height: size);

    final iconSize = size * (withBackground ? 0.48 : 0.9);
    final icon = FaIcon(
      brand.icon,
      size: iconSize,
      color: withBackground ? brand.iconColor : brand.brandColor,
    );

    if (!withBackground) {
      return SizedBox(width: size, height: size, child: Center(child: icon));
    }

    return _boxed(
      background: brand.brandColor,
      gradient: brand.gradient,
      child: icon,
    );
  }

  Widget _boxed({
    required Color background,
    Gradient? gradient,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: child,
    );
  }

  static _BrandStyle? _brandFor(String id) {
    return switch (id) {
      'facebook' || 'meta' => const _BrandStyle(
          icon: FontAwesomeIcons.facebook,
          brandColor: Color(0xFF1877F2),
        ),
      'instagram' => const _BrandStyle(
          icon: FontAwesomeIcons.instagram,
          brandColor: Color(0xFFE1306C),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFF58529),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
            ],
          ),
        ),
      'threads' || 'thread' => const _BrandStyle(
          icon: FontAwesomeIcons.threads,
          brandColor: Color(0xFF000000),
        ),
      'linkedin' => const _BrandStyle(
          icon: FontAwesomeIcons.linkedinIn,
          brandColor: Color(0xFF0A66C2),
        ),
      'linkedin_organization' ||
      'linkedin-organization' ||
      'linkedin_org' ||
      'linkedin_page' ||
      'linkedinorganization' => const _BrandStyle(
          icon: FontAwesomeIcons.linkedin,
          brandColor: Color(0xFFB8860B),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5D76E),
              Color(0xFFD4AF37),
              Color(0xFFB8860B),
              Color(0xFF8B6914),
            ],
          ),
        ),
      'tiktok' => const _BrandStyle(
          icon: FontAwesomeIcons.tiktok,
          brandColor: Color(0xFF010101),
        ),
      'x' || 'twitter' => const _BrandStyle(
          icon: FontAwesomeIcons.xTwitter,
          brandColor: Color(0xFF000000),
        ),
      'pinterest' => const _BrandStyle(
          icon: FontAwesomeIcons.pinterestP,
          brandColor: Color(0xFFE60023),
        ),
      'youtube' => const _BrandStyle(
          icon: FontAwesomeIcons.youtube,
          brandColor: Color(0xFFFF0000),
        ),
      _ => null,
    };
  }
}

class _BrandStyle {
  const _BrandStyle({
    required this.icon,
    required this.brandColor,
    this.gradient,
    this.iconColor = Colors.white,
  });

  final FaIconData icon;
  final Color brandColor;
  final Gradient? gradient;
  final Color iconColor;
}
