import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../models/community_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      await context.read<CommunityProvider>().loadActivities(user.id);
    }
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                context.read<CommunityProvider>().markActivitiesAsRead(user.id),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          final activities = provider.activities;

          if (!_initialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (activities.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityTile(activity);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔔', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Sign in to see your notifications',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥗', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'You are all caught up',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'New activity will appear here when people like, comment, and follow.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(ActivityModel activity) {
    final icon = _iconForType(activity.type);
    final color = _colorForType(activity.type);
    final title = _titleForActivity(activity);
    final subtitle = _subtitleForActivity(activity);
    final timeAgo = _formatTimeAgo(activity.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: activity.isRead
            ? Colors.white
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(ActivityType type) {
    switch (type) {
      case ActivityType.liked:
        return Iconsax.heart;
      case ActivityType.commented:
        return Iconsax.message;
      case ActivityType.followed:
        return Iconsax.user_add;
      case ActivityType.shared:
        return Iconsax.share;
      case ActivityType.mentioned:
        return Iconsax.tag;
      case ActivityType.newRecipe:
        return Iconsax.note_add;
      case ActivityType.challengeJoined:
        return Iconsax.cup;
      case ActivityType.badgeEarned:
        return Iconsax.crown;
    }
  }

  Color _colorForType(ActivityType type) {
    switch (type) {
      case ActivityType.liked:
        return Colors.redAccent;
      case ActivityType.commented:
        return Colors.blueAccent;
      case ActivityType.followed:
        return Colors.purpleAccent;
      case ActivityType.shared:
        return Colors.teal;
      case ActivityType.mentioned:
        return Colors.orangeAccent;
      case ActivityType.newRecipe:
        return Colors.green;
      case ActivityType.challengeJoined:
        return Colors.amber;
      case ActivityType.badgeEarned:
        return Colors.deepPurpleAccent;
    }
  }

  String _titleForActivity(ActivityModel activity) {
    switch (activity.type) {
      case ActivityType.liked:
        return '${activity.actorName} liked your recipe';
      case ActivityType.commented:
        return '${activity.actorName} commented on your recipe';
      case ActivityType.followed:
        return '${activity.actorName} started following you';
      case ActivityType.shared:
        return '${activity.actorName} shared your recipe';
      case ActivityType.mentioned:
        return '${activity.actorName} mentioned you';
      case ActivityType.newRecipe:
        return '${activity.actorName} published a new recipe';
      case ActivityType.challengeJoined:
        return '${activity.actorName} joined a challenge with you';
      case ActivityType.badgeEarned:
        return '${activity.actorName} earned a new badge';
    }
  }

  String? _subtitleForActivity(ActivityModel activity) {
    if (activity.message != null && activity.message!.isNotEmpty) {
      return activity.message;
    }
    return activity.targetTitle;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
