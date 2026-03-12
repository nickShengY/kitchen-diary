import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/community_model.dart';

/// Configuration for Neon Data API integration.
///
/// You should define these at build time, for example:
/// flutter run -d chrome --dart-define=NEON_DATA_API_URL=https://YOUR-PROJECT.neon.tech/rest/v1
///              --dart-define=NEON_DATA_API_KEY=YOUR_SERVICE_ROLE_KEY
///
/// IMPORTANT: For production you should NOT expose a powerful service key
/// directly to clients. Instead, put a lightweight backend in front of Neon
/// that issues per-user JWTs. This direct client integration is intended for
/// staging / development.
class NeonForumConfig {
  static const String baseUrl = String.fromEnvironment(
    'NEON_DATA_API_URL',
    defaultValue: '',
  );

  static const String apiKey = String.fromEnvironment(
    'NEON_DATA_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;
}

class ForumNeonService {
  ForumNeonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedBase = NeonForumConfig.baseUrl.endsWith('/')
        ? NeonForumConfig.baseUrl.substring(0, NeonForumConfig.baseUrl.length - 1)
        : NeonForumConfig.baseUrl;
    return Uri.parse('$normalizedBase$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${NeonForumConfig.apiKey}',
        'apikey': NeonForumConfig.apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Fetch latest forum posts ordered by pinned then created_at.
  Future<List<ForumPostModel>> fetchPosts({String? category, int limit = 20}) async {
    if (!NeonForumConfig.isConfigured) return [];

    final query = <String, String>{
      'select': '*',
      'order': 'is_pinned.desc,created_at.desc',
      'limit': '$limit',
    };

    if (category != null && category.isNotEmpty && category != 'all') {
      // PostgREST equality filter
      query['category'] = 'eq.$category';
    }

    final response = await _client.get(
      _buildUri('/forum_posts', query),
      headers: _headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => ForumPostModel.fromNeonJson(e as Map<String, dynamic>))
          .toList();
    }

    debugPrint(
      'Neon fetchPosts error: ${response.statusCode} ${response.body}',
    );
    return [];
  }

  /// Create a new forum post. Returns the created post with id.
  Future<ForumPostModel?> createPost(ForumPostModel post) async {
    if (!NeonForumConfig.isConfigured) return null;

    final body = jsonEncode([post.toNeonJson()]);

    final response = await _client.post(
      _buildUri('/forum_posts', {
        'select': '*',
      }),
      headers: {
        ..._headers,
        // Ask PostgREST/Data API to return inserted rows
        'Prefer': 'return=representation',
      },
      body: body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (data.isNotEmpty) {
        return ForumPostModel.fromNeonJson(data.first as Map<String, dynamic>);
      }
    } else {
      debugPrint('Neon createPost error: ${response.statusCode} ${response.body}');
    }

    return null;
  }

  /// Toggle like for a post by a user.
  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    if (!NeonForumConfig.isConfigured) return;

    // Call Postgres RPC function `toggle_post_like(post_id, user_id, is_liked)`
    final response = await _client.post(
      _buildUri('/rpc/toggle_post_like'),
      headers: _headers,
      body: jsonEncode({
        'post_id': postId,
        'user_id': userId,
        'is_liked': isLiked,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('Neon toggleLike error: ${response.statusCode} ${response.body}');
    }
  }
}
