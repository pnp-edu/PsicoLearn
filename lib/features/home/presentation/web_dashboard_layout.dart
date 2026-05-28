import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/security_service.dart';
import '../../../core/di/service_locator.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

/// Wraps the dashboard content with a web-optimized sidebar layout on large
/// screens (width >= 900) and falls back to the original mobile layout otherwise.
class WebDashboardLayout extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final Widget homeTab;
  final VoidCallback onContactAdmin;

  const WebDashboardLayout({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.homeTab,
    required this.onContactAdmin,
  });

  @override
  State<WebDashboardLayout> createState() => _WebDashboardLayoutState();
}

class _WebDashboardLayoutState extends State<WebDashboardLayout> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = kIsWeb && width >= 900;

    if (!isWide) {
      // Original mobile layout — return content unchanged
      return _buildMobileBody();
    }

    return _buildWebBody();
  }

  Widget _buildMobileBody() {
    return _buildContent();
  }

  Widget _buildWebBody() {
    final sidebarW = _sidebarCollapsed ? 72.0 : 220.0;
    return Row(
      children: [
        _WebSidebar(
          selectedIndex: widget.selectedIndex,
          onTabChanged: widget.onTabChanged,
          collapsed: _sidebarCollapsed,
          onToggleCollapse: () =>
              setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          onContactAdmin: widget.onContactAdmin,
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    final secService = sl<SecurityService>();
    switch (widget.selectedIndex) {
      case 0:
        return widget.homeTab;
      case 1:
        return ProfileScreen(
          onShowProgress: () => widget.onTabChanged(2),
          onSettingsPressed: () => widget.onTabChanged(3),
        );
      case 2:
        return ProgressScreen(onBack: () => widget.onTabChanged(0));
      case 3:
        return SettingsScreen(onBack: () => widget.onTabChanged(0));
      default:
        return widget.homeTab;
    }
  }
}

// ─────────────────────────────────────────────
// Web Sidebar
// ─────────────────────────────────────────────
class _WebSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onContactAdmin;

  const _WebSidebar({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.onContactAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? 72.0 : 220.0;
    final secService = sl<SecurityService>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117).withOpacity(0.92),
              border: Border(
                right: BorderSide(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo area
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: AppTheme.accentColor,
                          size: 22,
                        ),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'PsicoLearn',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),

                // Nav items
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  selected: selectedIndex == 0,
                  collapsed: collapsed,
                  onTap: () => onTabChanged(0),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  selected: selectedIndex == 1,
                  collapsed: collapsed,
                  onTap: () => onTabChanged(1),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Progreso',
                  selected: selectedIndex == 2,
                  collapsed: collapsed,
                  onTap: () => onTabChanged(2),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Ajustes',
                  selected: selectedIndex == 3,
                  collapsed: collapsed,
                  onTap: () => onTabChanged(3),
                ),

                const Spacer(),
                const Divider(color: Colors.white10, height: 1),

                // Admin button
                if (secService.isAdmin)
                  _NavItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin',
                    selected: false,
                    collapsed: collapsed,
                    accent: Colors.redAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminPanelScreen()),
                    ),
                  ),

                // Collapse toggle
                InkWell(
                  onTap: onToggleCollapse,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 48,
                    padding: EdgeInsets.symmetric(
                        horizontal: collapsed ? 16 : 14),
                    child: Row(
                      mainAxisAlignment: collapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          collapsed
                              ? Icons.keyboard_double_arrow_right_rounded
                              : Icons.keyboard_double_arrow_left_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                        if (!collapsed) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Contraer',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;
  final Color? accent;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? (selected ? AppTheme.accentColor : Colors.white60);
    final bgColor = selected
        ? AppTheme.accentColor.withOpacity(0.12)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3), width: 1)
                : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
