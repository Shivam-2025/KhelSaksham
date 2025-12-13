import 'package:flutter/material.dart';

class PrivateNavbar extends StatefulWidget {
  final Widget child; // <- screen content
  final String currentView;
  final Function(String) onNavigate;
  final VoidCallback onLogout;

  const PrivateNavbar({
    super.key,
    required this.child,
    required this.currentView,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  State<PrivateNavbar> createState() => _PrivateNavbarState();
}

class _PrivateNavbarState extends State<PrivateNavbar>
    with SingleTickerProviderStateMixin {
  bool sidebarOpen = false;
  late AnimationController _controller;
  late Animation<double> _slideAnim;

  final menuItems = const [
    {"view": "dashboard", "icon": "📊", "label": "Dashboard"},
    {"view": "profile", "icon": "👤", "label": "Profile"},
    {"view": "leaderboard", "icon": "🏆", "label": "Leaderboard"},
    {"view": "achievements", "icon": "🏅", "label": "Achievements"},
    {"view": "recording", "icon": "📹", "label": "Record"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main child screen (content area above navbar)
          Positioned.fill(
            bottom: 70, // leave space for bottom navbar
            child: widget.child,
          ),

          // Bottom Navbar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border:
                    const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2), // shadow upwards
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563eb),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sports_soccer,
                            size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("KhelSaksham",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1e293b))),
                          Text("खेळ सक्षम",
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748b))),
                        ],
                      ),
                    ],
                  ),

                  // Menu button
                  IconButton(
                    onPressed: toggleSidebar,
                    icon: const Icon(Icons.menu, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ),

          // Sidebar overlay
          if (sidebarOpen) ...[
            GestureDetector(
              onTap: toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Positioned(
                left: _slideAnim.value,
                top: 0,
                bottom: 70, // leave space for bottom navbar
                child: SafeArea( // ✅ FIX: Ensures sidebar respects notch/status bar
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📋 Menu",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1e293b))),
                        const SizedBox(height: 20),
                        ...menuItems.map((item) {
                          final isActive = widget.currentView == item["view"];
                          return GestureDetector(
                            onTap: () {
                              widget.onNavigate(item["view"]!);
                              toggleSidebar();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFdbeafe)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Text(item["icon"]!,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(item["label"]!,
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: isActive
                                              ? const Color(0xFF2563eb)
                                              : const Color(0xFF334155),
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.normal)),
                                ],
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            widget.onLogout();
                            toggleSidebar();
                          },
                          child: Row(
                            children: const [
                              Text("🚪", style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Text("Logout",
                                  style: TextStyle(
                                      fontSize: 15, color: Color(0xFFdc2626))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnim = Tween<double>(begin: -260, end: 0).animate(_controller);
  }

  void toggleSidebar() {
    setState(() {
      sidebarOpen = !sidebarOpen;
    });
    if (sidebarOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }
}
