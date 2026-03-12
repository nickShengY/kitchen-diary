import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/community_model.dart';
import '../../models/recipe_model.dart';
import '../../services/gemini_service.dart';
import '../../widgets/recipe/recipe_card.dart';
import '../../widgets/common/search_bar_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  String _selectedTag = 'All';
  bool _isSearching = false;
  bool _isGettingIdeas = false;
  int _currentTabIndex = 0;

  int _maxTimeMinutes = 0;
  RecipeDifficulty? _selectedDifficulty;
  MealType? _selectedMealType;
  String? _selectedCuisine;
  bool _onlyFeatured = false;
  bool _onlyWithVideo = false;

  final List<String> _tabs = ['For You', 'Popular', 'Following'];
  final List<String> _tags = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Healthy',
    'Quick',
    'Vegan'
  ];

  List<Map<String, String>> _availableCuisines(RecipeProvider recipeProvider) {
    final cuisines = <String>{};

    for (final recipe in [
      ...recipeProvider.recipes,
      ...recipeProvider.featuredRecipes,
    ]) {
      cuisines.addAll(
        recipe.cuisine
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      );
    }

    final sorted = cuisines.toList()..sort();
    return sorted.map((name) => {'name': name, 'emoji': ''}).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  void _reloadRecipes() {
    final tag = _selectedTag == 'All' ? null : _selectedTag;
    context.read<RecipeProvider>().loadRecipes(
          tag: tag,
          cuisine: _selectedCuisine,
          difficulty: _selectedDifficulty,
          mealType: _selectedMealType,
          sortBy: _sortByForTab(_currentTabIndex),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final recipeProvider = context.read<RecipeProvider>();
    final communityProvider = context.read<CommunityProvider>();
    final auth = context.read<AuthProvider>();

    recipeProvider.loadRecipes(
      tag: _selectedTag == 'All' ? null : _selectedTag,
      cuisine: _selectedCuisine,
      difficulty: _selectedDifficulty,
      mealType: _selectedMealType,
      sortBy: _sortByForTab(_currentTabIndex),
    );
    recipeProvider.loadFeaturedRecipes();
    communityProvider.loadTrendingRecipes();
    communityProvider.loadChallenges();
    communityProvider.loadForumPosts();

    // Preload notifications so the badge count is up to date
    final user = auth.user;
    if (user != null) {
      communityProvider.loadActivities(user.id);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_currentTabIndex != 1) {
        context.read<RecipeProvider>().loadMoreRecipes();
      }
    }
  }

  String _sortByForTab(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'popular';
      case 0:
      case 2:
      default:
        return 'recent';
    }
  }

  void _onTabSelected(int index) {
    if (_currentTabIndex == index) return;
    setState(() => _currentTabIndex = index);

    if (_isSearching) {
      return;
    }

    final recipeProvider = context.read<RecipeProvider>();
    final tag = _selectedTag == 'All' ? null : _selectedTag;
    recipeProvider.loadRecipes(
      tag: tag,
      cuisine: _selectedCuisine,
      difficulty: _selectedDifficulty,
      mealType: _selectedMealType,
      sortBy: _sortByForTab(index),
    );
  }

  void _onSearch(String query) async {
    final recipeProvider = context.read<RecipeProvider>();

    if (query.isEmpty) {
      setState(() => _isSearching = false);
      final tag = _selectedTag == 'All' ? null : _selectedTag;
      recipeProvider.loadRecipes(
        tag: tag,
        cuisine: _selectedCuisine,
        difficulty: _selectedDifficulty,
        mealType: _selectedMealType,
        sortBy: _sortByForTab(_currentTabIndex),
      );
      return;
    }

    setState(() => _isSearching = true);
    await recipeProvider.searchRecipesWithAI(query);
    await recipeProvider.searchRecipes(query);
    if (mounted) setState(() => _isSearching = false);
  }

  Future<void> _onGetIdeas() async {
    if (_isGettingIdeas) return;
    setState(() => _isGettingIdeas = true);
    try {
      await context
          .read<RecipeProvider>()
          .searchRecipesWithAI('Inspiration for tonight');
    } finally {
      if (mounted) {
        setState(() => _isGettingIdeas = false);
      }
    }
  }

  void _onTagSelected(String tag) {
    setState(() => _selectedTag = tag);

    if (tag == 'All') {
      context.read<RecipeProvider>().loadRecipes(
            cuisine: _selectedCuisine,
            difficulty: _selectedDifficulty,
            mealType: _selectedMealType,
            sortBy: _sortByForTab(_currentTabIndex),
          );
    } else {
      context.read<RecipeProvider>().loadRecipes(
            tag: tag,
            cuisine: _selectedCuisine,
            difficulty: _selectedDifficulty,
            mealType: _selectedMealType,
            sortBy: _sortByForTab(_currentTabIndex),
          );
    }
  }

  int _activeFilterCount() {
    var count = 0;
    if (_maxTimeMinutes > 0) count++;
    if (_selectedDifficulty != null) count++;
    if (_selectedMealType != null) count++;
    if (_selectedCuisine != null && _selectedCuisine!.isNotEmpty) count++;
    if (_onlyFeatured) count++;
    if (_onlyWithVideo) count++;
    return count;
  }

  Future<void> _openFilters() async {
    var maxTimeMinutes = _maxTimeMinutes;
    var selectedDifficulty = _selectedDifficulty;
    var selectedMealType = _selectedMealType;
    var selectedCuisine = _selectedCuisine;
    var onlyFeatured = _onlyFeatured;
    var onlyWithVideo = _onlyWithVideo;

    final cuisines = _availableCuisines(context.read<RecipeProvider>());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget sectionTitle(String text) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }

            String timeLabel() {
              if (maxTimeMinutes <= 0) return 'Any time';
              if (maxTimeMinutes < 60) return 'Up to $maxTimeMinutes min';
              final hours = (maxTimeMinutes / 60).floor();
              final mins = maxTimeMinutes % 60;
              return mins == 0 ? 'Up to ${hours}h' : 'Up to ${hours}h ${mins}m';
            }

            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filters',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              maxTimeMinutes = 0;
                              selectedDifficulty = null;
                              selectedMealType = null;
                              selectedCuisine = null;
                              onlyFeatured = false;
                              onlyWithVideo = false;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        sectionTitle('Time'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      timeLabel(),
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (maxTimeMinutes > 0)
                                      TextButton(
                                        onPressed: () => setSheetState(
                                            () => maxTimeMinutes = 0),
                                        child: const Text('Clear'),
                                      ),
                                  ],
                                ),
                                Slider(
                                  value: maxTimeMinutes.toDouble(),
                                  min: 0,
                                  max: 180,
                                  divisions: 12,
                                  label: timeLabel(),
                                  onChanged: (value) {
                                    setSheetState(() {
                                      maxTimeMinutes = value.round();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        sectionTitle('Difficulty'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ChoiceChip(
                                label: const Text('Any'),
                                selected: selectedDifficulty == null,
                                onSelected: (_) => setSheetState(
                                    () => selectedDifficulty = null),
                              ),
                              ...RecipeDifficulty.values.map(
                                (d) {
                                  final label = d.name[0].toUpperCase() +
                                      d.name.substring(1);
                                  return ChoiceChip(
                                    label: Text(label),
                                    selected: selectedDifficulty == d,
                                    onSelected: (_) => setSheetState(
                                        () => selectedDifficulty = d),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        sectionTitle('Meal type'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ChoiceChip(
                                label: const Text('Any'),
                                selected: selectedMealType == null,
                                onSelected: (_) => setSheetState(
                                    () => selectedMealType = null),
                              ),
                              ...MealType.values.map(
                                (m) {
                                  final label = m.name[0].toUpperCase() +
                                      m.name.substring(1);
                                  return ChoiceChip(
                                    label: Text(label),
                                    selected: selectedMealType == m,
                                    onSelected: (_) => setSheetState(
                                        () => selectedMealType = m),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        sectionTitle('Cuisine'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: cuisines.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest
                                        .withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Cuisine filters will appear when real recipes with cuisine data are available.',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Any'),
                                      selected: selectedCuisine == null,
                                      onSelected: (_) => setSheetState(
                                        () => selectedCuisine = null,
                                      ),
                                    ),
                                    ...cuisines.map(
                                      (c) {
                                        final name =
                                            c['name']?.toString() ?? '';
                                        final emoji =
                                            c['emoji']?.toString() ?? '';
                                        final label = emoji.isEmpty
                                            ? name
                                            : '$emoji $name';
                                        return ChoiceChip(
                                          label: Text(label),
                                          selected: selectedCuisine == name,
                                          onSelected: (_) => setSheetState(
                                            () => selectedCuisine =
                                                selectedCuisine == name
                                                    ? null
                                                    : name,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                        ),
                        sectionTitle('Quick toggles'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilterChip(
                                label: const Text('Featured'),
                                selected: onlyFeatured,
                                onSelected: (v) =>
                                    setSheetState(() => onlyFeatured = v),
                              ),
                              FilterChip(
                                label: const Text('Has video'),
                                selected: onlyWithVideo,
                                onSelected: (v) =>
                                    setSheetState(() => onlyWithVideo = v),
                              ),
                              FilterChip(
                                label: const Text('Quick (≤30m)'),
                                selected:
                                    maxTimeMinutes > 0 && maxTimeMinutes <= 30,
                                onSelected: (v) => setSheetState(() {
                                  if (v) {
                                    maxTimeMinutes = 30;
                                  } else if (maxTimeMinutes <= 30) {
                                    maxTimeMinutes = 0;
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _maxTimeMinutes = maxTimeMinutes;
                            _selectedDifficulty = selectedDifficulty;
                            _selectedMealType = selectedMealType;
                            _selectedCuisine = selectedCuisine;
                            _onlyFeatured = onlyFeatured;
                            _onlyWithVideo = onlyWithVideo;
                          });

                          final tag =
                              _selectedTag == 'All' ? null : _selectedTag;
                          context.read<RecipeProvider>().loadRecipes(
                                tag: tag,
                                cuisine: _selectedCuisine,
                                difficulty: _selectedDifficulty,
                                mealType: _selectedMealType,
                                sortBy: _sortByForTab(_currentTabIndex),
                              );

                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply filters'),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unreadNotifications =
        context.watch<CommunityProvider>().unreadActivityCount;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: scheme.primary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    final greeting = _getGreeting();
                                    final name =
                                        auth.user?.displayName ?? 'Chef';
                                    return Text(
                                      '$greeting, $name! 👋',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'What would you like to cook today?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                          Row(
                            children: [
                              _buildIconButton(
                                icon: Icons.tune_rounded,
                                onTap: _openFilters,
                                badge: _activeFilterCount() == 0
                                    ? null
                                    : _activeFilterCount(),
                              ),
                              const SizedBox(width: 8),
                              _buildIconButton(
                                icon: Iconsax.scan,
                                onTap: () => context.push('/menu-scanner'),
                                isPremium: true,
                              ),
                              const SizedBox(width: 8),
                              _buildIconButton(
                                icon: Iconsax.notification,
                                onTap: () => context.push('/notifications'),
                                badge: unreadNotifications,
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Search bar
                      SearchBarWidget(
                        controller: _searchController,
                        onSearch: _onSearch,
                        isSearching: _isSearching,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // Tags
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _tags.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final tag = _tags[index];
                            final isSelected = tag == _selectedTag;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _onTagSelected(tag),
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? scheme.primary
                                        : scheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? scheme.primary
                                          : scheme.outline
                                              .withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: isSelected
                                            ? scheme.onPrimary
                                            : scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                      if (_activeFilterCount() > 0) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_maxTimeMinutes > 0)
                              InputChip(
                                label: Text('≤ ${_maxTimeMinutes}m'),
                                onDeleted: () {
                                  setState(() => _maxTimeMinutes = 0);
                                },
                              ),
                            if (_selectedDifficulty != null)
                              InputChip(
                                label: Text(
                                  _selectedDifficulty!.name[0].toUpperCase() +
                                      _selectedDifficulty!.name.substring(1),
                                ),
                                onDeleted: () {
                                  setState(() => _selectedDifficulty = null);
                                  _reloadRecipes();
                                },
                              ),
                            if (_selectedMealType != null)
                              InputChip(
                                label: Text(
                                  _selectedMealType!.name[0].toUpperCase() +
                                      _selectedMealType!.name.substring(1),
                                ),
                                onDeleted: () {
                                  setState(() => _selectedMealType = null);
                                  _reloadRecipes();
                                },
                              ),
                            if (_selectedCuisine != null)
                              InputChip(
                                label: Text(_selectedCuisine!),
                                onDeleted: () {
                                  setState(() => _selectedCuisine = null);
                                  _reloadRecipes();
                                },
                              ),
                            if (_onlyFeatured)
                              InputChip(
                                label: const Text('Featured'),
                                onDeleted: () {
                                  setState(() => _onlyFeatured = false);
                                },
                              ),
                            if (_onlyWithVideo)
                              InputChip(
                                label: const Text('Has video'),
                                onDeleted: () {
                                  setState(() => _onlyWithVideo = false);
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Quick Tools Discovery
              SliverToBoxAdapter(
                child: _buildQuickToolsSection(),
              ),

              // Featured Section
              SliverToBoxAdapter(
                child: _buildFeaturedSection(),
              ),

              // Challenges Section
              SliverToBoxAdapter(
                child: _buildChallengesSection(),
              ),

              SliverToBoxAdapter(
                child: _buildCommunitySection(),
              ),

              // Daily Inspiration Card
              SliverToBoxAdapter(
                child: _buildDailyInspirationCard(),
              ),

              // AI Suggestions from Gemini
              SliverToBoxAdapter(
                child: _buildAiSuggestionsSection(),
              ),

              // Tab Bar
              SliverToBoxAdapter(
                child: Container(
                  color: theme.scaffoldBackgroundColor,
                  child: TabBar(
                    controller: _tabController,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    onTap: _onTabSelected,
                    labelColor: scheme.primary,
                    unselectedLabelColor: scheme.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    indicatorColor: scheme.primary,
                    indicatorWeight: 3,
                  ),
                ),
              ),

              // Recipe Grid
              Consumer<RecipeProvider>(
                builder: (context, provider, _) {
                  final auth = context.watch<AuthProvider>();
                  final following = auth.user?.following ?? const <String>[];
                  final showFollowing = _currentTabIndex == 2;
                  var filteredRecipes = showFollowing && following.isNotEmpty
                      ? provider.recipes
                          .where((r) => following.contains(r.authorId))
                          .toList()
                      : provider.recipes;

                  if (_maxTimeMinutes > 0) {
                    filteredRecipes = filteredRecipes
                        .where((r) => r.totalTimeMinutes <= _maxTimeMinutes)
                        .toList();
                  }
                  if (_onlyFeatured) {
                    filteredRecipes =
                        filteredRecipes.where((r) => r.isFeatured).toList();
                  }
                  if (_onlyWithVideo) {
                    filteredRecipes = filteredRecipes
                        .where((r) => (r.videoUrl ?? '').isNotEmpty)
                        .toList();
                  }

                  if (provider.isLoading && filteredRecipes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildLoadingGrid(),
                    );
                  }

                  if (showFollowing && following.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildFollowingEmptyState(),
                    );
                  }

                  if (filteredRecipes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () => context.push('/recipe/${recipe.id}'),
                          showQuickActions: true,
                        )
                            .animate()
                            .fadeIn(delay: (100 * (index % 4)).ms)
                            .slideY(begin: 0.1, end: 0);
                      },
                    ),
                  );
                },
              ),

              // Loading indicator
              Consumer<RecipeProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.recipes.isNotEmpty) {
                    if (_currentTabIndex == 1) {
                      return const SliverToBoxAdapter(
                          child: SizedBox(height: 100));
                    }
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox(height: 100));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPremium = false,
    int? badge,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: scheme.onSurface, size: 22),
                  if (isPremium)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: AppColors.premiumGradient,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  if (badge != null && badge > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: scheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickToolsSection() {
    final scheme = Theme.of(context).colorScheme;
    final tools = [
      {
        'emoji': '🤖',
        'label': 'AI Chef',
        'route': '/ai-chef',
        'color': AppColors.primary
      },
      {
        'emoji': '📅',
        'label': 'Meal Plan',
        'route': '/meal-planner',
        'color': AppColors.accent
      },
      {
        'emoji': '🧊',
        'label': 'Pantry',
        'route': '/pantry',
        'color': AppColors.success
      },
      {
        'emoji': '📊',
        'label': 'Nutrition',
        'route': '/nutrition',
        'color': AppColors.info
      },
      {
        'emoji': '⏱️',
        'label': 'Timers',
        'route': '/timers',
        'color': AppColors.secondary
      },
      {
        'emoji': '🧑‍🍳',
        'label': 'Smart Cook',
        'route': '/what-can-i-cook',
        'color': AppColors.primaryDark
      },
      {
        'emoji': '🏆',
        'label': 'Challenges',
        'route': '/challenges',
        'color': AppColors.warning
      },
      {
        'emoji': '📸',
        'label': 'Stories',
        'route': '/stories',
        'color': AppColors.error
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚀 Quick Tools',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tools.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final tool = tools[index];
                final color = tool['color'] as Color;
                return GestureDetector(
                  onTap: () => context.push(tool['route'] as String),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              tool['emoji'] as String,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tool['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.15);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        if (provider.featuredRecipes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '✨ Featured',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See all'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: provider.featuredRecipes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final recipe = provider.featuredRecipes[index];
                  return _buildFeaturedCard(recipe);
                },
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms);
      },
    );
  }

  Widget _buildFeaturedCard(RecipeModel recipe) {
    final imageUrl = recipe.imageUrl ??
        (recipe.imageUrls.isNotEmpty ? recipe.imageUrls.first : null);

    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}'),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    alignment: Alignment.center,
                    child: const Text('🍽️', style: TextStyle(fontSize: 42)),
                  ),
                )
              else
                Container(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  alignment: Alignment.center,
                  child: const Text('🍽️', style: TextStyle(fontSize: 42)),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            recipe.authorAvatar,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          recipe.authorName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Iconsax.heart5,
                          color: Colors.red.shade300,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.likes}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.timer_1,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.totalTimeMinutes} min',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengesSection() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        final activeChallenge =
            provider.challenges.isNotEmpty ? provider.challenges.first : null;

        if (activeChallenge == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🏆 CHALLENGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        activeChallenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeChallenge.participantsCount} chefs participating',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('🎯', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildCommunitySection() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        final posts = provider.forumPosts;
        if (posts.isEmpty && provider.isLoading) {
          return const SizedBox.shrink();
        }
        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: scheme.outline.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask questions, share tips, and get inspired.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => context.push('/forum'),
                    icon: const Icon(Iconsax.message),
                    label: const Text('Open'),
                  ),
                ],
              ),
            ),
          );
        }

        final preview = posts.take(6).toList(growable: false);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💬 Community',
                    style: theme.textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => context.push('/forum'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final post = preview[index];
                    return _buildCommunityPostCard(post);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityPostCard(ForumPostModel post) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/forum/post/${post.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primary.withValues(alpha: 0.10),
                    child: Text(
                      post.authorAvatar,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post.authorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.isPinned)
                    Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Iconsax.heart, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Iconsax.message,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👥', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No followed chefs yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Follow creators to see their latest recipes here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push('/forum'),
            icon: const Icon(Iconsax.message),
            label: const Text('Find people'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyInspirationCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('⭐', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Inspiration',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "What's for dinner tonight?",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _isGettingIdeas ? null : _onGetIdeas,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isGettingIdeas
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      )
                    : const Text(
                        'Get Ideas',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  /// AI suggestions from Gemini shown under Daily Inspiration.
  Widget _buildAiSuggestionsSection() {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        final suggestions = provider.aiSuggestions;
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Ideas for You',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => provider.clearAiSuggestions(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return _buildAiIdeaCard(suggestion);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiIdeaCard(RecipeSuggestion suggestion) {
    return GestureDetector(
      onTap: () {
        final query = suggestion.title;
        _searchController.text = query;
        _onSearch(query);
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    suggestion.difficulty.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Iconsax.timer_1,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${suggestion.estimatedMinutes} min',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              suggestion.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (suggestion.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: suggestion.tags.take(3).map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: index.isEven ? 200 : 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍳', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No recipes found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or explore our categories',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// SliverTabBarDelegate removed - using SliverToBoxAdapter instead
