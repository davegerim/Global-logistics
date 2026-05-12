import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:global_logistics_app/core/constants/app_colors.dart';
import 'package:global_logistics_app/data/storage/app_launch_preferences.dart';
import 'package:global_logistics_app/shared/widgets/gl_primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const List<_WalkthroughData> _pages = [
    _WalkthroughData(
      title: 'Global Logistics\nSimplified.',
      description:
          'Experience the future of freight management with real-time visibility and trusted execution.',
      imagePath: 'assets/images/shutterstock_1292121985-scaled (1).jpg',
      accentColor: AppColors.primary,
    ),
    _WalkthroughData(
      title: 'Connected\nOperations.',
      description:
          'Bring your team, drivers, and consignors together on one powerful platform.',
      imagePath: 'assets/images/f94634998aa00df20afd13beb197d04d.jpg',
      accentColor: AppColors.primaryLight,
    ),
    _WalkthroughData(
      title: 'Track Every\nJourney.',
      description:
          'Stay informed with real-time updates and milestone tracking from booking to delivery.',
      imagePath: 'assets/images/54596645_2.webp',
      accentColor: AppColors.gold,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToRoleSelection() async {
    await AppLaunchPreferences.instance.setIntroWalkthroughDone();
    if (!mounted) return;
    context.go('/role');
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _goToRoleSelection();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Images
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_pages[index].imagePath, fit: BoxFit.cover),
                  // Dark Overlay for readability
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Header
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.public,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                TextButton(
                  onPressed: _goToRoleSelection,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.8),
                  ),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Content Area (Aspirational Card)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Animated Text Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: Column(
                      key: ValueKey<int>(_currentPage),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pages[_currentPage].title,
                          style: t.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[_currentPage].description,
                          style: t.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Professional Button
                  Row(
                    children: [
                      Expanded(
                        child: GlPrimaryButton(
                          label: _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next Step',
                          onPressed: _nextPage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.check
                                : Icons.chevron_right,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkthroughData {
  const _WalkthroughData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String imagePath;
  final Color accentColor;
}
