import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_singleton.dart'; // Your API singleton

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> achievements = []; // Fetched from backend
  List<Map<String, Object>> performanceData = [
    {"x": "Pushups", "y": 80.0},
    {"x": "Situps", "y": 65.0},
    {"x": "Jumps", "y": 90.0},
    {"x": "Pullups", "y": 50.0},
    {"x": "Running", "y": 70.0},
  ];

  final quotes = [
    "Every rep counts 💪",
    "Consistency is key 🔑",
    "Push beyond limits 🚀",
    "Your sweat is your investment 💧",
    "Small progress is still progress 🌟",
    "Train insane or remain the same 🔥",
  ];

  final filters = ["All", "Strength", "Endurance", "Consistency"];
  String selectedFilter = "All";

  int currentQuoteIndex = 0;
  Timer? _quoteTimer;
  int touchedRadarIndex = -1;

  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  int selectedAchievementIndex = -1;
  bool isLoading = true;

  List<Map<String, dynamic>> get filteredAchievements {
    if (selectedFilter == "All") return achievements;
    return achievements
        .where((a) => a["category"] == selectedFilter)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    _quoteTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        currentQuoteIndex = (currentQuoteIndex + 1) % quotes.length;
      });
    });

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    fetchAchievements();
  }

  Future<void> fetchAchievements() async {
    try {
      final res = await api.getAchievements(); // API call
      final data = (res.data['achievements'] as List<dynamic>? ?? []);

      final loadedAchievements = data.map<Map<String, dynamic>>((a) {
        final item = a as Map<String, dynamic>;
        return {
          "title": item["title"] ?? "",
          "earned": item["earned"] ?? (item["earned_at"] != null),
          "progress": (item["progress"] ?? (item["earned_at"] != null ? 1.0 : 0.0))
              .toDouble(),
          "desc": item["description"] ?? "",
          "points": item["points"] ?? 0,
          "category": item["category"] ?? "Other",
          "earned_at": item["earned_at"],
        };
      }).toList();

      // Ensure Newcomer achievement exists
      final hasNewcomer = loadedAchievements.any((a) => a["title"] == "Newcomer");
      if (!hasNewcomer) {
        loadedAchievements.insert(0, {
          "title": "Newcomer",
          "earned": true,
          "progress": 1.0,
          "desc":
              "Welcome! You are just getting started on your fitness journey.",
          "points": 20,
          "category": "Consistency",
          "earned_at": DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        achievements = loadedAchievements;
        isLoading = false;
      });

      // Celebrate Newcomer if earned
      final newcomerIndex = achievements.indexWhere(
          (a) => a["title"] == "Newcomer" && a["earned"] == true);
      if (newcomerIndex != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _celebrate();
        });
      }
    } catch (e) {
      debugPrint("Error fetching achievements: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _confettiController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _celebrate() => _confettiController.play();
  void _shakeLockedAchievement() => _shakeController.forward(from: 0);

  void _showAchievementDetails(Map<String, dynamic> achievement, int index) {
    setState(() => selectedAchievementIndex = index);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Transform.rotate(
                    angle: value * 2 * pi,
                    child: Icon(
                      achievement["earned"] ? Icons.emoji_events : Icons.lock,
                      size: 80,
                      color: achievement["earned"]
                          ? const Color(0xFF16a34a)
                          : Colors.grey,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              achievement["title"] as String,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${achievement["points"]} Points",
                style: const TextStyle(
                  color: Color(0xFF2563eb),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement["desc"] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (!achievement["earned"]) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Progress",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      Text(
                        "${((achievement["progress"] as double) * 100).toInt()}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563eb),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder(
                    tween: Tween<double>(
                      begin: 0,
                      end: achievement["progress"] as double,
                    ),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, double value, child) {
                      return Stack(
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563eb),
                                    Color(0xFF3b82f6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563eb)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Keep pushing! You're almost there! 💪"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Start Training",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _celebrate();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Achievement shared! 🎉"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text(
                    "Share Achievement",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16a34a),
                    side: const BorderSide(color: Color(0xFF16a34a), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).then((_) {
      setState(() => selectedAchievementIndex = -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFf8fafc),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Achievements",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  quotes[currentQuoteIndex],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _InteractiveStatCard(
                        label: "Achievements",
                        value:
                            "${achievements.where((a) => a["earned"] == true).length}/${achievements.length}",
                        color: const Color(0xFF2563eb),
                        icon: Icons.emoji_events,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${achievements.where((a) => a["earned"] == false).length} more to unlock!",
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InteractiveStatCard(
                        label: "Points",
                        value:
                            "${achievements.where((a) => a["earned"] == true).fold<int>(0, (sum, a) => sum + (a["points"] as int))}",
                        color: const Color(0xFF16a34a),
                        icon: Icons.stars,
                        onTap: () {
                          final totalPossible = achievements.fold<int>(
                            0,
                            (sum, a) => sum + (a["points"] as int),
                          );
                          final earned = achievements
                              .where((a) => a["earned"] == true)
                              .fold<int>(
                                  0, (sum, a) => sum + (a["points"] as int));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("$earned / $totalPossible total points"),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      final isSelected = filter == selectedFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => selectedFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredAchievements.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final ach = filteredAchievements[index];
                    final isEarned = ach["earned"] == true;
                    final isSelectedRecent = selectedAchievementIndex == index;
                    return GestureDetector(
                      onTap: () {
                        if (isEarned) {
                          _showAchievementDetails(ach, index);
                        } else {
                          _shakeLockedAchievement();
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: isSelectedRecent && !isEarned
                                ? Offset(_shakeAnimation.value, 0)
                                : Offset.zero,
                            child: ScaleTransition(
                              scale: isEarned ? _pulseAnimation : kAlwaysCompleteAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isEarned
                                        ? const Color(0xFF16a34a)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isEarned ? Icons.emoji_events : Icons.lock,
                                      size: 36,
                                      color: isEarned
                                          ? const Color(0xFF16a34a)
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ach["title"] as String,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isEarned
                                            ? const Color(0xFF1e293b)
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${ach["points"]} pts",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isEarned
                                            ? const Color(0xFF16a34a)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  "Performance Overview",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: RadarChart(
                    RadarChartData(
                      dataSets: [
                        RadarDataSet(
                          dataEntries: performanceData
                              .map((e) =>
                                  RadarEntry(value: (e["y"] as double).clamp(0, 100)))
                              .toList(),
                          borderColor: const Color(0xFF2563eb),
                          fillColor: const Color(0xFF2563eb).withOpacity(0.2),
                        ),
                      ],
                      radarBackgroundColor: Colors.transparent,
                      radarBorderData: const BorderSide(color: Colors.transparent),
                      titleTextStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                      // ✅ FIXED: Proper title generator for fl_chart v0.69+
                      getTitle: (index, angle) {
                        return RadarChartTitle(
                          text: performanceData[index]["x"] as String,
                        );
                      },
                      tickCount: 5,
                      ticksTextStyle: const TextStyle(fontSize: 10, color: Colors.grey),
                      tickBorderData: const BorderSide(color: Colors.grey, width: 1),
                      gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 7,
            minBlastForce: 3,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.03,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [
              Color(0xFF16a34a),
              Color(0xFF2563eb),
              Color(0xFFf59e0b),
              Color(0xFFef4444),
              Color(0xFF8b5cf6),
            ],
          ),
        ),
      ],
    );
  }
}

// Interactive Stat Card
class _InteractiveStatCard extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _InteractiveStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_InteractiveStatCard> createState() => _InteractiveStatCardState();
}

class _InteractiveStatCardState extends State<_InteractiveStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    widget.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: widget.color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(widget.icon, color: widget.color, size: 24),
                      const Icon(
                        Icons.touch_app,
                        color: Color(0xFF94a3b8),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
