import 'package:flutter/material.dart';

enum ResponsiveContentProfile {
  compact,
  balanced,
  premium,
}

class ResponsiveContentShell extends StatelessWidget {
  final Widget child;
  final ResponsiveContentProfile profile;

  const ResponsiveContentShell({
    super.key,
    required this.child,
    this.profile = ResponsiveContentProfile.balanced,
  });

  const ResponsiveContentShell.premium({
    super.key,
    required this.child,
  }) : profile = ResponsiveContentProfile.premium;

  const ResponsiveContentShell.compact({
    super.key,
    required this.child,
  }) : profile = ResponsiveContentProfile.compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxContentWidth = _maxContentWidthFor(width);
        final horizontalPadding = _horizontalPaddingFor(width);

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }

  double _maxContentWidthFor(double width) {
    switch (profile) {
      case ResponsiveContentProfile.compact:
        if (width >= 1440) return 1200;
        if (width >= 1024) return 1024;
        if (width >= 768) return 760;
        return double.infinity;
      case ResponsiveContentProfile.premium:
        if (width >= 1600) return 1120;
        if (width >= 1280) return 1024;
        if (width >= 1024) return 940;
        if (width >= 768) return 700;
        return double.infinity;
      case ResponsiveContentProfile.balanced:
        if (width >= 1440) return 1100;
        if (width >= 1024) return 960;
        if (width >= 768) return 720;
        return double.infinity;
    }
  }

  double _horizontalPaddingFor(double width) {
    switch (profile) {
      case ResponsiveContentProfile.compact:
        if (width >= 1440) return 28;
        if (width >= 1024) return 24;
        if (width >= 768) return 20;
        return 0;
      case ResponsiveContentProfile.premium:
        if (width >= 1600) return 80;
        if (width >= 1280) return 56;
        if (width >= 1024) return 40;
        if (width >= 768) return 28;
        return 0;
      case ResponsiveContentProfile.balanced:
        if (width >= 1440) return 40;
        if (width >= 1024) return 32;
        if (width >= 768) return 24;
        return 0;
    }
  }
}
