import 'package:flutter/material.dart';

class HeroScreen extends StatefulWidget {
  final VoidCallback? onExplore;
  final VoidCallback? onAuth;

  const HeroScreen({super.key, this.onExplore, this.onAuth});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  final GlobalKey ctaSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Calculate navbar height to add proper spacing
    final topPadding = MediaQuery.of(context).padding.top;
    final navbarHeight = topPadding + 80; // navbar height + status bar
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/cosmic-bg.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Add spacing to account for the navbar
                SizedBox(height: navbarHeight),

                // Title
                Text(
                  "KhelSaksham\nखेळ सक्षम",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                const Text(
                  "Democratizing sports talent discovery through AI-powered assessment for every Indian athlete",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Color(0xFF475569)),
                ),

                const SizedBox(height: 12),

                // Secondary text
                const Text(
                  "Record your performance, get AI-powered feedback, compare with benchmarks, and unlock your potential in sports talent assessment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
                ),

                const SizedBox(height: 20),

                // CTA buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onExplore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Explore",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: scrollToCTA,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563eb)),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.play_circle_outline,
                        color: Color(0xFF2563eb),
                      ),
                      label: const Text(
                        "Learn More",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563eb),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _StatCard(
                      icon: Icons.person,
                      value: "10,000+",
                      label: "Athletes",
                    ),
                    _StatCard(
                      icon: Icons.sports_football,
                      value: "50,000+",
                      label: "Assessments",
                    ),
                    _StatCard(
                      icon: Icons.emoji_events,
                      value: "94%",
                      label: "Success Rate",
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // CTA Section with GlobalKey
                Container(
                  key: ctaSectionKey,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2563eb).withOpacity(0.1),
                        const Color(0xFF3b82f6).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2563eb).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "How It Works",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Your journey to athletic excellence in 3 simple steps",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748b),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Step 1 - Record
                      _ProcessStep(
                        icon: Icons.videocam,
                        title: "Record Your Performance",
                        description:
                            "Capture your athletic activities using your smartphone. Our app guides you through proper recording techniques for accurate assessment.",
                        color: const Color(0xFF2563eb),
                      ),

                      const SizedBox(height: 24),

                      // Step 2 - Analysis
                      _ProcessStep(
                        icon: Icons.analytics,
                        title: "On-Device Analysis & Ranking",
                        description:
                            "Advanced AI processes your performance locally on your device. Get instant feedback, detailed metrics, and see your position on the leaderboard.",
                        color: const Color(0xFF16a34a),
                      ),

                      const SizedBox(height: 24),

                      // Step 3 - Scouting
                      _ProcessStep(
                        icon: Icons.people,
                        title: "Get Scouted by Coaches",
                        description:
                            "Top performers get noticed by professional coaches and scouts. Unlock opportunities to join elite training programs and advance your sports career.",
                        color: const Color(0xFFf59e0b),
                      ),

                      const SizedBox(height: 40),

                      // Get Started button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563eb),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(
                            Icons.rocket_launch,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: const Text(
                            "Get Started Now",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void scrollToCTA() {
    Scrollable.ensureVisible(
      ctaSectionKey.currentContext!,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }
}

// Updated Process Step Widget - No step numbers
class _ProcessStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _ProcessStep({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle instead of number
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1e293b),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748b),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Color(0xFF2563eb)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1e293b),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
