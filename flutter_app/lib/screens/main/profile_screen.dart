import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/recipe/recipe_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isCheckingFollow = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;
    final viewedUserId = widget.userId ?? currentUser?.id;

    if (viewedUserId != null) {
      context.read<RecipeProvider>().loadUserRecipes(viewedUserId);
      if (widget.userId != null) {
        context.read<UserProvider>().getUser(viewedUserId);
      }
    }

    if (widget.userId != null &&
        currentUser != null &&
        widget.userId != currentUser.id) {
      _checkFollowStatus(currentUser.id, widget.userId!);
    }
  }

  Future<void> _checkFollowStatus(
      String currentUserId, String targetUserId) async {
    setState(() {
      _isCheckingFollow = true;
    });
    final auth = context.read<AuthProvider>();
    final isFollowing = await auth.isFollowing(targetUserId);
    if (!mounted) return;
    setState(() {
      _isFollowing = isFollowing;
      _isCheckingFollow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = auth.user;
    final isOwnProfile =
        widget.userId == null || widget.userId == currentUser?.id;
    final viewedUser = isOwnProfile ? currentUser : userProvider.viewedUser;

    if (isOwnProfile && viewedUser == null) {
      return _buildLoginPrompt();
    }

    if (!isOwnProfile && viewedUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isVip = isOwnProfile ? subscription.isVip : (viewedUser!.isVip);

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Header actions
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isOwnProfile)
                            IconButton(
                              onPressed: () => context.pop(),
                              icon: const Icon(Iconsax.arrow_left),
                            )
                          else
                            const SizedBox(width: 48),
                          Row(
                            children: [
                              if (isOwnProfile) ...[
                                IconButton(
                                  onPressed: () =>
                                      context.push('/subscription'),
                                  icon: Icon(
                                    Iconsax.crown,
                                    color: subscription.isVip
                                        ? Colors.amber
                                        : AppColors.textLight,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context.push('/settings'),
                                  icon: const Icon(Iconsax.setting_2),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Profile header
                    _buildProfileHeader(viewedUser!, isOwnProfile, isVip),

                    const SizedBox(height: 24),

                    // Stats
                    _buildStats(viewedUser),

                    const SizedBox(height: 24),

                    // Action buttons
                    if (isOwnProfile)
                      _buildProfileActions(viewedUser)
                    else
                      _buildFollowButton(viewedUser),

                    if (isOwnProfile) ...[
                      const SizedBox(height: 20),
                      _buildMyKitchenTools(),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Recipes'),
                      Tab(text: 'Favorites'),
                      Tab(text: 'Collections'),
                    ],
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textLight,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRecipesTab(),
              _buildFavoritesTab(),
              _buildCollectionsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🍳', style: TextStyle(fontSize: 48)),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 2000.ms,
                    ),
                const SizedBox(height: 32),
                Text(
                  'Kitchen Diary',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the cutest cooking community!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, bool isOwnProfile, bool isVip) {
    return Column(
      children: [
        // Avatar
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isVip ? Colors.amber : Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isVip
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: user.photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.photoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        user.avatarEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
            ),
            if (isVip)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Iconsax.crown5,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

        const SizedBox(height: 16),

        // Name
        Text(
          user.displayName,
          style: Theme.of(context).textTheme.headlineMedium,
        ).animate().fadeIn(delay: 200.ms),

        // Bio
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            user.bio!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
        ],

        // Badges
        if (user.badges.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: user.badges.take(3).map<Widget>((badge) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ],
    );
  }

  Widget _buildStats(UserModel user) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = auth.user;
    final isOwnProfile =
        widget.userId == null || widget.userId == currentUser?.id;

    final recipesCount = user.recipesCount;
    final likesCount = user.likesReceived;

    int followersCount;
    if (isOwnProfile && auth.neonProfile != null) {
      followersCount = auth.followersCount;
    } else if (!isOwnProfile && userProvider.viewedUserNeonProfile != null) {
      followersCount = userProvider.viewedUserFollowersCount;
    } else {
      followersCount = user.followers.length;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('$recipesCount', 'Recipes'),
          _buildStatDivider(),
          _buildStatItem('$followersCount', 'Followers'),
          _buildStatDivider(),
          _buildStatItem('$likesCount', 'Likes'),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.textLight.withValues(alpha: 0.2),
    );
  }

  Widget _buildMyKitchenTools() {
    final scheme = Theme.of(context).colorScheme;
    final tools = [
      {'emoji': '📅', 'label': 'Meal Plan', 'route': '/meal-planner'},
      {'emoji': '🧊', 'label': 'Pantry', 'route': '/pantry'},
      {'emoji': '📊', 'label': 'Nutrition', 'route': '/nutrition'},
      {'emoji': '🤖', 'label': 'AI Chef', 'route': '/ai-chef'},
      {'emoji': '⏱️', 'label': 'Timers', 'route': '/timers'},
      {'emoji': '🧑‍🍳', 'label': 'Smart Cook', 'route': '/what-can-i-cook'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Kitchen',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push(tool['route'] as String),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tool['emoji'] as String,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        tool['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildProfileActions(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Iconsax.edit, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareProfile(user),
              icon: const Icon(Iconsax.share, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Future<void> _shareProfile(UserModel user) async {
    // Build a web-friendly profile URL. On web this will use the current
    // origin (http://localhost:8080 or production domain) plus the
    // Flutter route for user profiles.
    final base = Uri.base;
    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    final profileUrl = '$origin/#/user/${user.id}';

    final message =
        'Check out ${user.displayName} on Kitchen Diary!\n$profileUrl';

    await Share.share(
      message,
      subject: 'Kitchen Diary profile',
    );
  }

  Widget _buildFollowButton(UserModel viewedUser) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isCheckingFollow
              ? null
              : () async {
                  if (currentUser == null) {
                    context.go('/login');
                    return;
                  }

                  setState(() {
                    _isCheckingFollow = true;
                  });

                  bool success;
                  if (_isFollowing) {
                    success = await auth.unfollowUser(viewedUser.id);
                  } else {
                    success = await auth.followUser(viewedUser.id);
                  }

                  if (!mounted) return;

                  setState(() {
                    if (success) {
                      _isFollowing = !_isFollowing;
                    }
                    _isCheckingFollow = false;
                  });
                },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isCheckingFollow
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isFollowing ? 'Following' : 'Follow'),
        ),
      ),
    );
  }

  Widget _buildRecipesTab() {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        if (provider.userRecipes.isEmpty) {
          return _buildEmptyTab(
            emoji: '📝',
            title: 'No recipes yet',
            subtitle: 'Start creating your first recipe!',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: provider.userRecipes.length,
          itemBuilder: (context, index) {
            final recipe = provider.userRecipes[index];
            return RecipeCard(
              recipe: recipe,
              onTap: () => context.push('/recipe/${recipe.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return _buildEmptyTab(
      emoji: '❤️',
      title: 'No favorites yet',
      subtitle: 'Like recipes to add them here!',
    );
  }

  Widget _buildCollectionsTab() {
    return _buildEmptyTab(
      emoji: '📚',
      title: 'No collections yet',
      subtitle: 'Create collections to organize recipes!',
    );
  }

  Widget _buildEmptyTab({
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
