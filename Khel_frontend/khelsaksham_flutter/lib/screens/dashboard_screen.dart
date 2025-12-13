import 'package:flutter/material.dart';
import '../services/api_singleton.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      // ⚠️ You’ll need to pass token here if backend requires it
      final response = await api.getDashboard(); 
      if (mounted) {
        setState(() {
          dashboardData = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Failed to load dashboard";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmall = constraints.maxWidth < 400;
                            return isSmall
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Performance Vault",
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1e293b))),
                                      const Text(
                                          "Your athletic performance dashboard",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF475569))),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const _SyncStatus(),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  const Color(0xFF334155),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: _fetchDashboard,
                                            icon: const Icon(Icons.refresh,
                                                size: 18),
                                            label: const Text("Sync Now",
                                                style:
                                                    TextStyle(fontSize: 13)),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text("Performance Vault",
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1e293b))),
                                          Text(
                                              "Your athletic performance dashboard",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF475569))),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const _SyncStatus(),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor:
                                                  const Color(0xFF334155),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 0,
                                            ),
                                            onPressed: _fetchDashboard,
                                            icon: const Icon(Icons.refresh,
                                                size: 18),
                                            label: const Text("Sync Now",
                                                style:
                                                    TextStyle(fontSize: 13)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Stats Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 600;
                            final crossAxisCount = isWide ? 2 : 2;
                            final stats = [
                              {
                                "label": "Total Reps",
                                "value": dashboardData?["total_reps"] ?? 0,
                                "trend": "",
                                "icon": Icons.fitness_center,
                                "color": const Color(0xFF2563eb)
                              },
                              {
                                "label": "Best Workout",
                                "value": dashboardData?["best_workout"] ?? 0,
                                "trend": "",
                                "icon": Icons.emoji_events,
                                "color": const Color(0xFF059669)
                              },
                            ];
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: stats.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                              itemBuilder: (context, index) {
                                final stat = stats[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2))
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Text(stat["trend"].toString(),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: (stat["color"] as Color)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(stat["icon"] as IconData,
                                            color: stat["color"] as Color,
                                            size: 20),
                                      ),
                                      const SizedBox(height: 12),
                                      Text("${stat["value"]}",
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1e293b))),
                                      Text(stat["label"].toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748b))),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Weekly Trend Chart
                        _CardContainer(
                          title: "Weekly Trend",
                          icon: Icons.show_chart,
                          iconColor: const Color(0xFF2563eb),
                          child: (dashboardData?["weekly_trend"] == null ||
                                  (dashboardData?["weekly_trend"] as List)
                                      .isEmpty)
                              ? const Center(
                                  child: Text("No data yet"),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: (dashboardData?["weekly_trend"]
                                          as List<dynamic>)
                                      .map((item) {
                                    final reps = (item["reps"] ?? 0) as int;
                                    final maxScore =
                                        (dashboardData?["weekly_trend"]
                                                as List<dynamic>)
                                            .map((d) => (d["reps"] ?? 0) as int)
                                            .fold<int>(
                                                0,
                                                (a, b) =>
                                                    a > b ? a : b);
                                    final double height = maxScore == 0
                                        ? 0
                                        : (reps / maxScore) * 120.0;
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 20,
                                          height: height.toDouble(),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563eb),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item["day"].toString(),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF475569))),
                                        Text("${item["reps"]}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),

                        // Recent Activities
                        _CardContainer(
                          title: "Recent Activities",
                          icon: Icons.sports_soccer,
                          iconColor: const Color(0xFF059669),
                          child: (dashboardData?["recent_activity"] == null ||
                                  (dashboardData?["recent_activity"] as List)
                                      .isEmpty)
                              ? const Center(child: Text("No activities yet"))
                              : Column(
                                  children: (dashboardData?["recent_activity"]
                                          as List<dynamic>)
                                      .map((act) => _ActivityRow(
                                          act["exercise"],
                                          act["timestamp"],
                                          act["reps"],
                                          Icons.fitness_center))
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// Recent activity row
class _ActivityRow extends StatelessWidget {
  final String activity;
  final String time;
  final int score;
  final IconData icon;

  const _ActivityRow(this.activity, this.time, this.score, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
              color: const Color(0xFFf1f5f9),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: const Color(0xFF475569)),
        ),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(activity,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1e293b))),
            Text(time,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
          ]),
        ),
        Text("$score reps",
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563eb))),
      ]),
    );
  }
}

// Reusable card container
class _CardContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _CardContainer(
      {required this.title,
      required this.icon,
      required this.iconColor,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1e293b))),
          Icon(icon, size: 20, color: iconColor),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

// Sync status widget
class _SyncStatus extends StatelessWidget {
  const _SyncStatus();

  @override
  Widget build(BuildContext context) {
    const status = "synced"; // placeholder
    final config = {
      "synced": {
        "color": Color(0xFF059669),
        "icon": Icons.check_circle,
        "text": "Synced"
      },
      "pending": {
        "color": Color(0xFFf59e0b),
        "icon": Icons.sync,
        "text": "Syncing..."
      },
      "error": {
        "color": Color(0xFFdc2626),
        "icon": Icons.error,
        "text": "Sync Error"
      },
    };

    final c = config[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: (c["color"] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(c["icon"] as IconData, size: 16, color: c["color"] as Color),
          const SizedBox(width: 4),
          Text(c["text"] as String,
              style: TextStyle(
                  color: c["color"] as Color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}