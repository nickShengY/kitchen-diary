import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/main/main_shell.dart';
import '../../screens/main/explore_screen.dart';
import '../../screens/main/procedure_builder_screen.dart';
import '../../screens/main/decider_screen.dart';
import '../../screens/main/profile_screen.dart';
import '../../screens/recipe/recipe_detail_screen.dart';
import '../../screens/recipe/cooking_mode_screen.dart';
import '../../screens/community/forum_screen.dart';
import '../../screens/community/post_detail_screen.dart';
import '../../screens/community/create_post_screen.dart';
import '../../screens/community/notifications_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/subscription_screen.dart';
import '../../screens/settings/wheel_settings_screen.dart';
import '../../screens/menu_scanner/menu_scanner_screen.dart';
import '../../screens/animation/animation_composer_screen.dart';
import '../../screens/meal_planner/meal_planner_screen.dart';
import '../../screens/pantry/pantry_screen.dart';
import '../../screens/nutrition/nutrition_screen.dart';
import '../../screens/ai_chef/ai_chef_screen.dart';
import '../../screens/timer/cooking_timer_screen.dart';
import '../../screens/smart_cook/what_can_i_cook_screen.dart';
import '../../screens/community/challenges_screen.dart';
import '../../screens/community/stories_screen.dart';
import '../../screens/share/share_recipe_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      // If not authenticated and not on auth route, redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // If authenticated and on auth route (except splash), redirect to home
      if (isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/explore';
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/explore',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExploreScreen(),
            ),
          ),
          GoRoute(
            path: '/create',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProcedureBuilderScreen(),
            ),
          ),
          GoRoute(
            path: '/decider',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeciderScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Recipe routes
      GoRoute(
        path: '/recipe/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final recipeId = state.pathParameters['id']!;
          return MaterialPage(
            child: RecipeDetailScreen(recipeId: recipeId),
          );
        },
      ),
      GoRoute(
        path: '/recipe/:id/cook',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final recipeId = state.pathParameters['id']!;
          return MaterialPage(
            child: CookingModeScreen(recipeId: recipeId),
          );
        },
      ),
      GoRoute(
        path: '/recipe/edit/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final recipeId = state.pathParameters['id'];
          return MaterialPage(
            child: ProcedureBuilderScreen(recipeId: recipeId),
          );
        },
      ),

      // Community/Forum routes
      GoRoute(
        path: '/forum',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: ForumScreen(),
        ),
      ),
      GoRoute(
        path: '/forum/post/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final postId = state.pathParameters['id']!;
          return MaterialPage(
            child: PostDetailScreen(postId: postId),
          );
        },
      ),
      GoRoute(
        path: '/forum/create',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: CreatePostScreen(),
        ),
      ),

      // User profile route
      GoRoute(
        path: '/user/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['id']!;
          return MaterialPage(
            child: ProfileScreen(userId: userId),
          );
        },
      ),

      // Settings routes
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: SubscriptionScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/wheel-settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: WheelSettingsScreen(),
        ),
      ),

      // Meal Planner Module
      GoRoute(
        path: '/meal-planner',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MealPlannerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Pantry Manager Module
      GoRoute(
        path: '/pantry',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PantryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Nutrition & Health Dashboard Module
      GoRoute(
        path: '/nutrition',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NutritionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // AI Chef Assistant
      GoRoute(
        path: '/ai-chef',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AiChefScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      // Cooking Timers
      GoRoute(
        path: '/timers',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CookingTimerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // What Can I Cook - Smart Recipe Matcher
      GoRoute(
        path: '/what-can-i-cook',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WhatCanICookScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Cooking Challenges
      GoRoute(
        path: '/challenges',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChallengesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Community Stories / Reels
      GoRoute(
        path: '/stories',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StoriesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      // Share Recipe
      GoRoute(
        path: '/share/:recipeId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final recipeId = state.pathParameters['recipeId']!;
          final title = state.uri.queryParameters['title'] ?? 'Recipe';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ShareRecipeScreen(recipeId: recipeId, recipeTitle: title),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),

      // Menu Scanner (VIP feature)
      GoRoute(
        path: '/menu-scanner',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: MenuScannerScreen(),
        ),
      ),

      // Animation Composer - Create custom recipe animations
      GoRoute(
        path: '/animation-composer',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnimationComposerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),

      // Animation Composer with recipe
      GoRoute(
        path: '/animation-composer/:recipeId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          // final recipeId = state.pathParameters['recipeId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AnimationComposerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🍳',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ??
                  'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
