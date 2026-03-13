import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: FontAwesomeIcons.globe,
      title: 'Discover events worldwide',
      subtitle: 'Browse trending, nearby, and virtual events from every corner of the globe.',
    ),
    _OnboardingPage(
      icon: FontAwesomeIcons.comments,
      title: 'Join live chats & RSVP instantly',
      subtitle: 'Chat with attendees in real time and secure your spot with one tap.',
    ),
    _OnboardingPage(
      icon: FontAwesomeIcons.calendarPlus,
      title: 'Create your own gathering',
      subtitle: 'Host in-person or virtual events and grow your community.',
    ),
  ];

  void _onGetStarted() {
    ref.read(onboardingCompletedProvider.notifier).state = true;
    AppStorage.setOnboardingCompleted(true);
    context.replace('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) {
                    final p = _pages[i];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context) + 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(p.icon, size: Responsive.iconSize(context, 80), color: Colors.white)
                              .animate()
                              .scale(curve: Curves.elasticOut)
                              .fadeIn(),
                          SizedBox(height: Responsive.spacing(context, 32)),
                          Text(
                            p.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                          SizedBox(height: Responsive.spacing(context, 12)),
                          Text(
                            p.subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: Responsive.spacing(context, 4)),
                    width: _page == i ? Responsive.value(context, 24) : Responsive.value(context, 8),
                    height: Responsive.value(context, 8),
                    decoration: BoxDecoration(
                      color: _page == i ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(Responsive.value(context, 4)),
                    ),
                  );
                }),
              ),
              SizedBox(height: Responsive.spacing(context, 32)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context) + 4),
                child: FilledButton(
                  onPressed: _onGetStarted,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: Size(double.infinity, Responsive.buttonMinHeight(context)),
                  ),
                  child: const Text('Get Started'),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
              SizedBox(height: Responsive.spacing(context, 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardingPage({required this.icon, required this.title, required this.subtitle});
}
