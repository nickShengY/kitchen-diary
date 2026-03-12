import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/pantry_provider.dart';

class AiChefScreen extends StatefulWidget {
  const AiChefScreen({super.key});

  @override
  State<AiChefScreen> createState() => _AiChefScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _AiChefScreenState extends State<AiChefScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  final _quickPrompts = [
    '🥗 What can I cook with what I have?',
    '🍝 Suggest a quick dinner under 30 min',
    '🎂 Help me with a birthday cake recipe',
    '🥘 Give me a healthy meal prep idea',
    '🌮 Suggest a vegetarian Mexican dish',
    '🍜 What pairs well with chicken?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text:
          'Hi! I\'m your AI Chef Assistant 👨‍🍳\n\nI can help you with:\n• Recipe suggestions based on ingredients\n• Cooking tips & techniques\n• Meal planning advice\n• Ingredient substitutions\n• Dietary recommendations\n\nWhat would you like to cook today?',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 800 + 400), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: _generateResponse(text),
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  String _generateResponse(String query) {
    final q = query.toLowerCase();

    if (q.contains('what can i cook') || q.contains('what i have')) {
      final pantry = context.read<PantryProvider>();
      final items = pantry.allItems.map((i) => i.name).take(8).join(', ');
      if (items.isNotEmpty) {
        return 'Based on your pantry ($items), here are some ideas:\n\n'
            '1. **Garlic Fried Rice** 🍚 - Quick and flavorful, uses rice, garlic, and eggs\n'
            '2. **Chicken Stir-Fry** 🥘 - Toss chicken with any vegetables you have\n'
            '3. **Pasta Aglio e Olio** 🍝 - Simple pasta with garlic and olive oil\n\n'
            'Would you like the full recipe for any of these?';
      }
      return 'I\'d love to help! Add some items to your **Pantry** first, and I can suggest recipes based on what you have on hand. 🧊';
    }

    if (q.contains('quick') || q.contains('30 min') || q.contains('fast')) {
      return '⚡ Here are some quick dinner ideas:\n\n'
          '1. **One-Pan Lemon Herb Chicken** (25 min)\n   Chicken thighs with lemon, herbs, roasted in one pan\n\n'
          '2. **Shrimp Tacos** (20 min)\n   Seasoned shrimp, slaw, lime crema\n\n'
          '3. **Caprese Pasta** (15 min)\n   Fresh tomatoes, mozzarella, basil over pasta\n\n'
          'Want me to detail any of these? 🍽️';
    }

    if (q.contains('cake') || q.contains('birthday') || q.contains('baking')) {
      return '🎂 For a birthday cake, here\'s a crowd-pleaser:\n\n'
          '**Classic Vanilla Layer Cake**\n'
          '• 3 layers of moist vanilla sponge\n'
          '• Buttercream frosting\n'
          '• Total time: ~2 hours\n\n'
          '**Key tips:**\n'
          '• Room temp ingredients for best results\n'
          '• Don\'t overmix the batter\n'
          '• Let layers cool completely before frosting\n\n'
          'Shall I give you the full recipe with measurements?';
    }

    if (q.contains('healthy') || q.contains('meal prep')) {
      return '🥗 Great choice! Here\'s a meal prep plan:\n\n'
          '**Mediterranean Bowl Prep** (makes 5 servings)\n'
          '• Quinoa base\n'
          '• Grilled chicken or chickpeas\n'
          '• Roasted veggies (bell peppers, zucchini)\n'
          '• Hummus + tzatziki\n'
          '• Cherry tomatoes + cucumber\n\n'
          '**Prep time:** 45 min for the whole week!\n'
          '**~450 cal per serving** with balanced macros\n\n'
          'Want me to create a shopping list for this?';
    }

    if (q.contains('substitut')) {
      return '🔄 Common ingredient substitutions:\n\n'
          '• **Butter** → Coconut oil, applesauce (baking)\n'
          '• **Eggs** → Flax eggs, banana, aquafaba\n'
          '• **Milk** → Oat/almond/soy milk\n'
          '• **Cream** → Coconut cream, cashew cream\n'
          '• **Soy sauce** → Coconut aminos, tamari\n\n'
          'What specific ingredient do you need to substitute?';
    }

    if (q.contains('vegetarian') || q.contains('vegan')) {
      return '🌿 Delicious plant-based ideas:\n\n'
          '1. **Black Bean Tacos** with mango salsa\n'
          '2. **Mushroom Risotto** - rich and creamy\n'
          '3. **Thai Green Curry** with tofu\n'
          '4. **Stuffed Bell Peppers** with quinoa\n\n'
          'All packed with protein and flavor! Which one interests you?';
    }

    if (q.contains('pair') || q.contains('goes with') || q.contains('side')) {
      return '🍷 Great pairings depend on your main:\n\n'
          '**With Chicken:**\n'
          '• Roasted vegetables, mashed potatoes\n'
          '• Caesar salad, rice pilaf\n\n'
          '**With Fish:**\n'
          '• Lemon butter asparagus, couscous\n'
          '• Mango salsa, cilantro lime rice\n\n'
          '**With Pasta:**\n'
          '• Garlic bread, Italian salad\n'
          '• Roasted broccoli, bruschetta\n\n'
          'What\'s your main dish?';
    }

    return 'That\'s a great question! 🤔\n\n'
        'Here are some thoughts:\n'
        '• Try exploring our **Explore** tab for trending recipes\n'
        '• Check your **Pantry** to see what ingredients you have\n'
        '• Use the **Meal Planner** to organize your week\n\n'
        'Is there something specific I can help you with? I\'m great at:\n'
        '• Recipe suggestions\n'
        '• Cooking techniques\n'
        '• Ingredient substitutions\n'
        '• Meal planning';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Chef',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(
                  _isTyping ? 'Cooking up an answer...' : 'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isTyping ? AppColors.primary : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: scheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: 'Chat cleared! How can I help you today? 👨‍🍳',
                  isUser: false,
                ));
              });
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(scheme);
                }
                final message = _messages[index];
                return _buildMessageBubble(scheme, message, index);
              },
            ),
          ),
          if (_messages.length <= 1)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickPrompts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _quickPrompts[index],
                        style: TextStyle(fontSize: 12, color: scheme.onSurface),
                      ),
                      backgroundColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _sendMessage(_quickPrompts[index]),
                    ),
                  ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.2);
                },
              ),
            ),
          _buildInputBar(scheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      ColorScheme scheme, _ChatMessage message, int index) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: EdgeInsets.only(
          bottom: 8,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? scheme.onPrimary : scheme.onSurface,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    ).animate(delay: (50).ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildTypingIndicator(ColorScheme scheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            )
                .animate(
                  onPlay: (ctrl) => ctrl.repeat(),
                )
                .moveY(
                    begin: 0,
                    end: -6,
                    duration: 400.ms,
                    delay: (i * 150).ms,
                    curve: Curves.easeInOut)
                .then()
                .moveY(
                    begin: -6,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeInOut);
          }),
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask me anything about cooking...',
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: const Icon(Iconsax.send_1, color: Colors.white, size: 22),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ),
        ],
      ),
    );
  }
}
