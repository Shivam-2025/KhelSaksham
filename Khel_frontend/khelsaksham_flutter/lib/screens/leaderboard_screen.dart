import 'package:flutter/material.dart';
import '../services/api_singleton.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String sortBy = "rank";
  String filterSport = "all";
  String searchQuery = "";

  List<Map<String, dynamic>> leaderboard = [];
  Map<String, dynamic>? userRank; // Logged-in user's rank
  bool isLoading = true;

  final List<String> allSports = [
    "all",
    "Athletics",
    "Swimming",
    "Gymnastics",
    "Football",
    "Basketball",
    "Cricket",
    "Kabaddi",
    "Hockey",
    "Volleyball",
    "Tennis",
    "Badminton",
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => isLoading = true);
    try {
      final data = await api.fetchLeaderboard();

      // Find current user in the leaderboard
      final currentUserRank = data.firstWhere(
        (e) => e['is_current_user'] == true,
        orElse: () => {"rank": 0, "score": 0, "username": "You"},
      );

      setState(() {
        leaderboard = data.cast<Map<String, dynamic>>();
        userRank = currentUserRank; // Show rank even if #0 for new users
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Leaderboard fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = leaderboard
        .where((a) => filterSport == "all" || a["sport"] == filterSport)
        .toList()
      ..sort((a, b) {
        final aScore = a["score"] ?? 0;
        final bScore = b["score"] ?? 0;
        return sortBy == "score"
            ? bScore.compareTo(aScore)
            : (a["rank"] ?? 0).compareTo(b["rank"] ?? 0);
      });

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text(
          "Pantheon of Champions",
          style: TextStyle(
            color: Color(0xFF1e293b),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () =>
                setState(() => sortBy = sortBy == "rank" ? "score" : "rank"),
            child: Text(
              "Sort: $sortBy",
              style: const TextStyle(color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "India's top athletic talents competing nationwide",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 20),

                    // Hamburger filter
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _openSportsFilter,
                        icon: const Icon(Icons.menu, size: 18),
                        label: Text(
                          filterSport == "all" ? "All Sports" : filterSport,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563eb),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Top 3 Podium
                    if (filtered.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: filtered.take(3).map((a) {
                          final bgColor = (a["rank"] ?? 0) == 1
                              ? const Color(0xFFfacc15)
                              : (a["rank"] ?? 0) == 2
                                  ? const Color(0xFFd1d5db)
                                  : const Color(0xFFf59e0b);
                          return Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: (a["avatar"] ?? "").isNotEmpty
                                    ? NetworkImage(a["avatar"])
                                    : null,
                                radius: 36,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 100,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "#${a["rank"] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      a["username"] ?? "Unknown",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "${a["score"] ?? 0}%",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // User Rank Card
                    if (userRank != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563eb),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You are ranked #${userRank!['rank'] ?? 0} with ${userRank!['score'] ?? 0}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Complete Rankings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full leaderboard list
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("No data available."))
                          : ListView(
                              children: filtered.map((a) {
                                final rank = a["rank"] ?? 0;
                                final name = a["username"] ?? "Unknown";
                                final location = a["location"] ?? "-";
                                final sport = a["sport"] ?? "-";
                                final score = a["score"] ?? 0;
                                final avatar = a["avatar"] ?? "";

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563eb),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        margin: const EdgeInsets.only(right: 10),
                                        child: Text(
                                          "#$rank",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      CircleAvatar(
                                        backgroundImage: avatar.isNotEmpty
                                            ? NetworkImage(avatar)
                                            : null,
                                        radius: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1e293b),
                                              ),
                                            ),
                                            Text(
                                              "$location · $sport",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF64748b),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "$score%",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF2563eb),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _openSportsFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> startsWithQuery = allSports
                .where(
                  (s) => s.toLowerCase().startsWith(searchQuery.toLowerCase()),
                )
                .toList();

            List<String> containsQuery = allSports
                .where(
                  (s) =>
                      !s.toLowerCase().startsWith(searchQuery.toLowerCase()) &&
                      s.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            List<String> filteredSports = [
              ...startsWithQuery,
              ...containsQuery,
            ];

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Search sports...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredSports.length,
                      itemBuilder: (context, index) {
                        final sport = filteredSports[index];
                        final isActive = filterSport == sport;
                        return ListTile(
                          title: Text(
                            sport == "all" ? "All Sports" : sport,
                            style: TextStyle(
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive
                                  ? const Color(0xFF2563eb)
                                  : Colors.black,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              filterSport = sport;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
