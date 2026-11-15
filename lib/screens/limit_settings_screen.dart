import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';
import '../models/daily_status.dart';
import '../services/detector_service.dart';

class LimitSettingsScreen extends StatefulWidget {
  const LimitSettingsScreen({super.key});

  @override
  State<LimitSettingsScreen> createState() => _LimitSettingsScreenState();
}

class _LimitSettingsScreenState extends State<LimitSettingsScreen> {
  final DetectorService _detector = DetectorService();
  int _sliderValue = 100;
  int _tomorrowSliderValue = 100;
  bool _initialized = false;

  final List<int> _presetOptions = const [25, 50, 100, 200, 300, 500];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  void _loadCurrent() {
    final status = _detector.statusNotifier.value;
    _sliderValue = status.dailyLimit;
    _tomorrowSliderValue = status.hasTomorrowLimitScheduled
        ? status.tomorrowLimit
        : status.dailyLimit;
    _initialized = true;
  }

  Future<void> _saveTodayLimit() async {
    final success = await _detector.setDailyQuota(_sliderValue);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Today\'s quota updated to $_sliderValue Reels.'),
          backgroundColor: AppColors.neonCyan,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot change today\'s limit: Daily limit has already been reached!'),
          backgroundColor: AppColors.neonPink,
        ),
      );
    }
  }

  Future<void> _saveTomorrowLimit() async {
    final success = await _detector.setTomorrowLimit(_tomorrowSliderValue);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tomorrow\'s limit scheduled: $_tomorrowSliderValue Reels (applies at midnight).'),
          backgroundColor: AppColors.neonPurpleLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Quota Settings'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<DailyStatus>(
          valueListenable: _detector.statusNotifier,
          builder: (context, status, _) {
            if (!_initialized) {
              _sliderValue = status.dailyLimit;
              _tomorrowSliderValue = status.hasTomorrowLimitScheduled
                  ? status.tomorrowLimit
                  : status.dailyLimit;
              _initialized = true;
            }
            final isReached = status.isLimitReached;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header description
                  const Text(
                    'Configure your daily Reels quota. When this quota is reached, REELLOCK will restrict Instagram Reels on your Samsung phone until the local midnight reset.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Today's Limit Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isReached
                            ? AppColors.neonPink.withValues(alpha: 0.5)
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TODAY\'S REELS QUOTA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isReached
                                    ? AppColors.neonPink.withValues(alpha: 0.2)
                                    : AppColors.neonPurple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isReached ? 'LOCKED TODAY' : 'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isReached ? AppColors.neonPink : AppColors.neonPurple,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              isReached ? '${status.dailyLimit}' : '$_sliderValue',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: isReached ? AppColors.neonPink : AppColors.neonPurple,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reels / day',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (isReached) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neonPink.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_rounded, color: AppColors.neonPink, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Today\'s quota is locked. To build real dopamine resistance, quotas cannot be increased once reached. You may schedule tomorrow\'s quota below.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Slider & Presets when not locked
                          Slider(
                            value: _sliderValue.toDouble(),
                            min: 10,
                            max: 500,
                            divisions: 49,
                            activeColor: AppColors.neonPurple,
                            inactiveColor: AppColors.surfaceElevated,
                            onChanged: (val) {
                              setState(() => _sliderValue = val.round());
                            },
                          ),

                          const SizedBox(height: 8),

                          // Preset buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _presetOptions.map((opt) {
                              final isSelected = _sliderValue == opt;
                              return ChoiceChip(
                                label: Text('$opt'),
                                selected: isSelected,
                                selectedColor: AppColors.neonPurple,
                                backgroundColor: AppColors.surfaceElevated,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                onSelected: (_) {
                                  setState(() => _sliderValue = opt);
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveTodayLimit,
                              child: const Text('Save Today\'s Quota'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Schedule Tomorrow's Limit Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SCHEDULE TOMORROW\'S QUOTA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (status.hasTomorrowLimitScheduled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'SCHEDULED: ${status.tomorrowLimit}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.neonCyan,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_tomorrowSliderValue',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: AppColors.neonCyan,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reels for tomorrow',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Slider(
                          value: _tomorrowSliderValue.toDouble(),
                          min: 10,
                          max: 500,
                          divisions: 49,
                          activeColor: AppColors.neonCyan,
                          inactiveColor: AppColors.surfaceElevated,
                          onChanged: (val) {
                            setState(() => _tomorrowSliderValue = val.round());
                          },
                        ),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presetOptions.map((opt) {
                            final isSelected = _tomorrowSliderValue == opt;
                            return ChoiceChip(
                              label: Text('$opt'),
                              selected: isSelected,
                              selectedColor: AppColors.neonCyan,
                              backgroundColor: AppColors.surfaceElevated,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.pureBlack : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              onSelected: (_) {
                                setState(() => _tomorrowSliderValue = opt);
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveTomorrowLimit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceElevated,
                              foregroundColor: AppColors.neonCyan,
                              side: const BorderSide(color: AppColors.neonCyan, width: 1),
                            ),
                            child: const Text('Schedule for Tomorrow (00:00 Reset)'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Educational Discipline Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.neonPurple, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Real Dopamine Baseline Protection',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Short-video feeds trigger micro-dopamine spikes that degrade attention span. Locking access at your chosen quota forces healthy disengagement.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
