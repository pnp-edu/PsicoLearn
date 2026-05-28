import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/security_service.dart';
import '../../../core/di/service_locator.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
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
    const isWide = true; // Force sidebar layout on mobile too

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
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: _buildContent(),
          ),
        ),
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
          onSettingsPressed: () => widget.onTabChanged(2),
        );
      case 2:
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
    final w = collapsed ? 80.0 : 280.0;
    final secService = sl<SecurityService>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: w,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          border: Border(
            right: BorderSide(
              color: AppTheme.accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo area with enhanced design
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentColor,
                          AppTheme.accentColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                AppTheme.accentColor,
                                Colors.white,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'PsicoLearn',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Text(
                            'Plataforma Pro',
                            style: TextStyle(
                              color: AppTheme.accentColor.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Navigation section
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'NAVEGACIÓN',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Nav items with enhanced design
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: selectedIndex == 0,
              collapsed: collapsed,
              onTap: () => onTabChanged(0),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Mi Perfil',
              selected: selectedIndex == 1,
              collapsed: collapsed,
              onTap: () => onTabChanged(1),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Configuración',
              selected: selectedIndex == 2,
              collapsed: collapsed,
              onTap: () => onTabChanged(2),
            ),

            const SizedBox(height: 24),

            // Tools section
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'HERRAMIENTAS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Contact admin button
            _NavItem(
              icon: Icons.support_agent_rounded,
              label: 'Soporte',
              selected: false,
              collapsed: collapsed,
              accent: AppTheme.accentColor,
              onTap: onContactAdmin,
            ),

            const Spacer(),

            // Admin section
            if (secService.isAdmin) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.redAccent.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _NavItem(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Panel Admin',
                selected: false,
                collapsed: collapsed,
                accent: Colors.redAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminPanelScreen()),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Collapse toggle with enhanced design
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: InkWell(
                onTap: onToggleCollapse,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        collapsed
                            ? Icons.keyboard_double_arrow_right_rounded
                            : Icons.keyboard_double_arrow_left_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Contraer',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
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
    final color = accent ?? (selected ? AppTheme.accentColor : Colors.white.withOpacity(0.7));
    final bgColor = selected
        ? AppTheme.accentColor.withOpacity(0.15)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(
                    color: AppTheme.accentColor.withOpacity(0.3), 
                    width: 1.5
                  )
                : null,
            boxShadow: selected ? [
              BoxShadow(
                color: AppTheme.accentColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 16),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected 
                      ? AppTheme.accentColor.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: color, 
                  size: 22
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
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
