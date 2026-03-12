import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth used via context.read<AuthProvider>() directly
    final subscription = context.watch<SubscriptionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account section
          _buildSectionHeader(context, 'Account'),

          _buildSettingItem(
            context,
            icon: Iconsax.user,
            title: 'Edit Profile',
            onTap: () {},
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.crown,
            title: 'VIP Subscription',
            subtitle: subscription.isVip ? 'Active' : 'Upgrade now',
            trailing: subscription.isVip
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
            onTap: () => context.push('/subscription'),
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.notification,
            title: 'Notifications',
            onTap: () {},
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.lock,
            title: 'Privacy',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Preferences section
          _buildSectionHeader(context, 'Preferences'),

          _buildSettingItem(
            context,
            icon: Iconsax.moon,
            title: 'Dark Mode',
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: scheme.primary,
            ),
            onTap: () => themeProvider.toggleTheme(),
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.chart,
            title: 'Customize Wheel',
            subtitle: 'Add or edit cuisines and dishes',
            onTap: () => context.push('/wheel-settings'),
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.language_square,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.ruler,
            title: 'Units',
            subtitle: 'Metric',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Support section
          _buildSectionHeader(context, 'Support'),

          _buildSettingItem(
            context,
            icon: Iconsax.message_question,
            title: 'Help Center',
            onTap: () {},
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.message,
            title: 'Contact Us',
            onTap: () => _launchEmail(),
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.star,
            title: 'Rate the App',
            onTap: () {},
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.share,
            title: 'Share with Friends',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Legal section
          _buildSectionHeader(context, 'Legal'),

          _buildSettingItem(
            context,
            icon: Iconsax.document,
            title: 'Terms of Service',
            onTap: () {},
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.shield_tick,
            title: 'Privacy Policy',
            onTap: () {},
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.document_text,
            title: 'Licenses',
            onTap: () => showLicensePage(context: context),
          ),

          const SizedBox(height: 24),

          // Danger zone
          _buildSectionHeader(context, 'Account Actions'),

          _buildSettingItem(
            context,
            icon: Iconsax.logout,
            title: 'Sign Out',
            textColor: scheme.error,
            onTap: () => _showSignOutDialog(context),
          ),

          _buildSettingItem(
            context,
            icon: Iconsax.trash,
            title: 'Delete Account',
            textColor: scheme.error,
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const SizedBox(height: 32),

          // Version info
          Center(
            child: Column(
              children: [
                Text(
                  'Kitchen Diary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    final effectiveTextColor = textColor ?? scheme.onSurface;
    final leadingColor = textColor ?? scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            onTap: onTap,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: leadingColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: leadingColor, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: effectiveTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  )
                : null,
            trailing: trailing ??
                Icon(
                  Iconsax.arrow_right_3,
                  color: scheme.onSurfaceVariant,
                  size: 18,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  void _launchEmail() async {
    final uri = Uri.parse('mailto:support@kitchendiary.app');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSignOutDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your recipes, collections, and data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success =
                  await context.read<AuthProvider>().deleteAccount();
              if (success && context.mounted) {
                Navigator.pop(context);
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
