import 'package:flutter/material.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Shown briefly when `/verify-otp` has no route args (cold start / deep link).
/// Matches [PostLoginStatusScreen] rehydrate loader so users never see a white frame.
class VerifyOtpMissingArgsPlaceholder extends StatelessWidget {
  const VerifyOtpMissingArgsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.thirdColor.withValues(alpha: 0.55),
              AppColors.surface,
            ],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToukhServiceLogo(size: 72),
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
