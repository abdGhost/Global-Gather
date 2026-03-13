import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      final token = await AppStorage.getStoredToken();
      final onboardingDone = await AppStorage.getOnboardingCompleted();
      if (!mounted) return;
      ref.read(onboardingCompletedProvider.notifier).state = onboardingDone;
      if (token != null && token.isNotEmpty) {
        ref.read(authTokenProvider.notifier).state = token;
        context.replace('/');
        return;
      }
      if (onboardingDone) {
        context.replace('/login');
      } else {
        context.replace('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.splashGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Animate(
                effects: const [
                  ScaleEffect(begin: Offset(0.3, 0.3), end: Offset(1, 1), curve: Curves.elasticOut),
                  FadeEffect(),
                ],
                child: Container(
                  padding: EdgeInsets.all(Responsive.value(context, 20)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: FaIcon(FontAwesomeIcons.champagneGlasses, size: Responsive.iconSize(context, 64), color: Colors.white),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, 24)),
              Text(
                'Global Gather',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 400))
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
              Text(
                'Discover events worldwide',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 600))
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
