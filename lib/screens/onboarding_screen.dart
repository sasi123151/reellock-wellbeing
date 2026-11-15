import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../services/detector_service.dart';
import 'main_shell_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final DetectorService _detector = DetectorService();

  int _currentPage = 0;
  bool _usageGranted = false;
  bool _accessibilityGranted = false;
  int _selectedLimit = 100;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final usage = await _detector.checkUsagePermission();
    final access = await _detector.checkAccessibilityPermission();
    if (mounted) {
      setState(() {
        _usageGranted = usage;
        _accessibilityGranted = access;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await _detector.setDailyQuota(_selectedLimit);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top page indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.neonPurple
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomeStep(),
                  _buildUsageAccessStep(),
                  _buildAccessibilityStep(),
                  _buildLimitStep(),
                ],
              ),
            ),

            // Bottom action button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonPurple,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == 3 ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPurple.withValues(alpha: 0.3),
                  blurRadius: 36,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.shield_rounded, size: 48, color: AppColors.neonPurple),
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'REELLOCK',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Instagram Reels Addiction Control',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.neonCyan,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Reclaim hours lost to endless swiping. Set strict daily Reels quotas and enforce real-world focus when your limit is reached.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageAccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: const Icon(Icons.timer_outlined, size: 44, color: AppColors.neonPurple),
          ),
          const SizedBox(height: 28),
          const Text(
            'Usage Access Permission',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Required by Android to measure your total daily foreground time in Instagram and track session duration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () async {
              await _detector.requestUsageAccess();
              await _checkPermissions();
            },
            icon: Icon(
              _usageGranted ? Icons.check_circle_rounded : Icons.lock_open_rounded,
              color: _usageGranted ? AppColors.neonCyan : AppColors.neonPurple,
            ),
            label: Text(
              _usageGranted ? 'Usage Access Granted' : 'Grant Usage Access',
              style: TextStyle(
                color: _usageGranted ? AppColors.neonCyan : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            child: const Icon(Icons.accessibility_new_rounded, size: 44, color: AppColors.neonPurple),
          ),
          const SizedBox(height: 28),
          const Text(
            'Accessibility Service',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Used strictly on-device to detect Reels viewer scroll transitions and enforce the limit screen when your daily quota is hit. No keystrokes or private messages are ever logged.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () async {
              await _detector.requestAccessibilityPermission();
              await _checkPermissions();
            },
            icon: Icon(
              _accessibilityGranted ? Icons.check_circle_rounded : Icons.toggle_on_rounded,
              color: _accessibilityGranted ? AppColors.neonCyan : AppColors.neonPurple,
            ),
            label: Text(
              _accessibilityGranted ? 'Accessibility Active' : 'Enable Service',
              style: TextStyle(
                color: _accessibilityGranted ? AppColors.neonCyan : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitStep() {
    const limits = [25, 50, 100, 200, 500];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Set Your Daily Reels Quota',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Default is 100 Reels per day. Once reached, REELLOCK will lock access until midnight.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: limits.map((l) {
              final isSelected = _selectedLimit == l;
              return InkWell(
                onTap: () => setState(() => _selectedLimit = l),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.neonPurple : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.neonPurple : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$l',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reels',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.neonCyan : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
