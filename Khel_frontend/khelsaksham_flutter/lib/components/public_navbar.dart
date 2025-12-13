import 'package:flutter/material.dart';

class PublicNavbar extends StatefulWidget {
  final VoidCallback? onLoginClick;
  final VoidCallback? onSignupClick;
  final Function(String)? onNavigate;

  const PublicNavbar({
    super.key,
    this.onLoginClick,
    this.onSignupClick,
    this.onNavigate,
  });

  @override
  State<PublicNavbar> createState() => _PublicNavbarState();
}

class _PublicNavbarState extends State<PublicNavbar> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Top Navbar - Full Width
          Container(
            width: screenWidth, // Full screen width
            margin: EdgeInsets.zero, // Remove horizontal margins
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.zero, // Remove border radius for full width
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                Flexible(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onNavigate?.call("home"),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563eb),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "KhelSaksham",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1e293b),
                                ),
                              ),
                              Text(
                                "खेळ सक्षम",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748b),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Right side buttons
                if (!isSmallScreen)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoginBtn(screenWidth),
                      const SizedBox(width: 12),
                      _buildSignupBtn(screenWidth),
                    ],
                  )
                else
                  IconButton(
                    icon: Icon(
                      _isMenuOpen ? Icons.close : Icons.menu,
                      color: const Color(0xFF334155),
                    ),
                    onPressed: () =>
                        setState(() => _isMenuOpen = !_isMenuOpen),
                  ),
              ],
            ),
          ),

          // Mobile dropdown menu - Full Width
          if (isSmallScreen && _isMenuOpen)
            Container(
              width: screenWidth, // Full screen width
              margin: EdgeInsets.zero, // Remove horizontal margins
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.zero, // Remove border radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLoginBtn(screenWidth),
                  const SizedBox(height: 8),
                  _buildSignupBtn(screenWidth),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant PublicNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (MediaQuery.of(context).size.width >= 500 && _isMenuOpen) {
      setState(() => _isMenuOpen = false);
    }
  }

  Widget _buildLoginBtn(double screenWidth) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: widget.onLoginClick,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFd1fae5),
          foregroundColor: const Color(0xFF1e40af),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Login",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSignupBtn(double screenWidth) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: widget.onSignupClick,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFdbeafe),
          foregroundColor: const Color(0xFF1e40af),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Sign Up",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
