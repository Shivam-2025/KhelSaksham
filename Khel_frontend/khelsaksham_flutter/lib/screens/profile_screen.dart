import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_singleton.dart';
import 'recording_screen.dart'; // <-- import for navigation

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Achievement card
class _AchievementCard extends StatelessWidget {
  final Map<String, dynamic> ach;
  const _AchievementCard({required this.ach});

  @override
  Widget build(BuildContext context) {
    final earned = ach["earned"] as bool;
    final bg =
        earned ? Colors.green.withOpacity(0.1) : const Color(0xFFe2e8f0);
    final iconColor =
        earned ? Colors.green : const Color(0xFF64748b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: earned
              ? const Color(0xFFf1f5f9)
              : const Color(0xFFe2e8f0).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.emoji_events,
                  color: iconColor, size: 20),
            ),
            Text(ach["title"] ?? "",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: earned
                        ? const Color(0xFF1e293b)
                        : const Color(0xFF64748b))),
            Text(ach["description"] ?? "",
                style: TextStyle(
                    fontSize: 12,
                    color: earned
                        ? const Color(0xFF475569)
                        : const Color(0xFF94a3b8))),
          ]),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> user = {
    "name": "",
    "age": 0,
    "location": "",
    "sport": "",
    "avatar": null,
    "stats": {
      "assessments": 0,
      "avg_score": 0,
      "rank": 0,
      "streak": 0,
    }
  };

  List<dynamic> achievements = [];
  bool editing = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await api.getProfile();
      final data = response.data;

      setState(() {
        user["name"] = data["username"] ?? "";
        user["age"] = data["age"] ?? 0;
        user["location"] = data["location"] ?? "";
        user["sport"] = data["sport"] ?? "";
        user["avatar"] = data["avatar_url"];
        user["stats"] = {
          "assessments": data["stats"]?["assessments"] ?? 0,
          "avg_score": data["stats"]?["avg_score"] ?? 0,
          "rank": data["stats"]?["rank"] ?? 0,
          "streak": data["stats"]?["streak"] ?? 0,
        };
      });

      final achRes = await api.getAchievements();
      setState(() {
        achievements = achRes.data ?? [];
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              editing ? _buildEditProfileCard() : _buildProfileCard(),
              _buildAchievements(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader("Achievements", Icons.emoji_events,
              const Color(0xFFf97316)),
          const SizedBox(height: 12),
          achievements.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "🎯 No achievements yet.\nStart your first workout to unlock one!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF475569)),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        constraints.maxWidth < 400 ? 1 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: achievements.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.8,
                      ),
                      itemBuilder: (context, index) =>
                          _AchievementCard(
                              ach: achievements[index]),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEditProfileCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _inputField("Full Name", user["name"],
              (val) => setState(() => user["name"] = val)),
          const SizedBox(height: 8),
          _inputField(
              "Age",
              user["age"].toString(),
              (val) => setState(() =>
                  user["age"] =
                      int.tryParse(val) ?? user["age"]),
              isNumber: true),
          const SizedBox(height: 8),
          _inputField("Location", user["location"],
              (val) => setState(() => user["location"] = val)),
          const SizedBox(height: 8),
          _inputField("Sport", user["sport"],
              (val) => setState(() => user["sport"] = val)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () =>
                    setState(() => editing = false),
                child: const Text("Cancel",
                    style: TextStyle(color: Color(0xFF64748b))),
              ),
              ElevatedButton(
                onPressed: () async {
                  await api.updateProfile(
                    email: null,
                    bio: null,
                    avatarUrl: user["avatar"],
                  );
                  _saveProfile();
                  setState(() => editing = false);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb)),
                child: const Text("Save",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: user["avatar"] != null
                ? CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        NetworkImage(user["avatar"]))
                : CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        const Color(0xFFe2e8f0),
                    child: const Icon(Icons.person,
                        size: 40, color: Color(0xFF94a3b8)),
                  ),
          ),
          const SizedBox(height: 8),
          Text(user["name"],
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b))),
          Text("${user["age"]} yrs • ${user["location"]}",
              style:
                  const TextStyle(color: Color(0xFF64748b))),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFdbeafe),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.sports_soccer,
                  size: 16, color: Color(0xFF2563eb)),
              const SizedBox(width: 4),
              Text(user["sport"],
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2563eb))),
            ]),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              _StatBox(
                  value: "${user["stats"]["assessments"]}",
                  label: "Assessments"),
              _StatBox(
                  value: "${user["stats"]["avg_score"]}",
                  label: "Avg Score"),
              _StatBox(
                  value: "${user["stats"]["rank"]}",
                  label: "Rank"),
              _StatBox(
                  value: "${user["stats"]["streak"]}",
                  label: "Streak"),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                setState(() => editing = true),
            icon: const Icon(Icons.edit,
                size: 18, color: Colors.white),
            label: const Text("Edit Profile",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
                padding: const EdgeInsets.symmetric(
                    vertical: 10)),
          ),
          const SizedBox(height: 12),
          // ✅ Start Test button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecordingScreen(
                    exercise: "pushups", // ✅ replace later with dynamic
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow,
                size: 18, color: Colors.white),
            label: const Text("Start Test",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                    vertical: 10)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2))
      ],
    );
  }

  Widget _cardHeader(
      String title, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1e293b))),
        Icon(icon, color: color)
      ],
    );
  }

  Widget _inputField(String hint, String value,
      Function(String) onChanged,
      {bool isNumber = false}) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      keyboardType: isNumber
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8))),
      style: const TextStyle(fontSize: 14),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => user["avatar"] = picked.path);
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("profile_name", user["name"]);
    prefs.setInt("profile_age", user["age"]);
    prefs.setString("profile_location", user["location"]);
    prefs.setString("profile_sport", user["sport"]);
    if (user["avatar"] != null) {
      prefs.setString("profile_avatar", user["avatar"]);
    }
  }
}

// Stat box
class _StatBox extends StatelessWidget {
  final String value, label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b))),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF64748b))),
      ]),
    );
  }
}
