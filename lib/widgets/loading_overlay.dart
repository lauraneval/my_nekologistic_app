import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const ColoredBox(
            color: Color(0x80FFFFFF),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          ),
      ],
    );
  }
}

class NekoLoadingIndicator extends StatelessWidget {
  const NekoLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryBlue,
        strokeWidth: 2.5,
      ),
    );
  }
}
