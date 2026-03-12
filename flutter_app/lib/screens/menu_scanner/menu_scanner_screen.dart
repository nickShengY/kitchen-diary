import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/subscription_provider.dart';
import '../../services/gemini_service.dart';
// subscription_service not needed - using provider

class MenuScannerScreen extends StatefulWidget {
  const MenuScannerScreen({super.key});

  @override
  State<MenuScannerScreen> createState() => _MenuScannerScreenState();
}

class _MenuScannerScreenState extends State<MenuScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  Uint8List? _imageBytes;
  bool _isScanning = false;
  ExtractedMenu? _extractedMenu;
  MenuItemExtracted? _selectedItem;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageBytes = bytes;
          _extractedMenu = null;
          _selectedItem = null;
          _error = null;
        });

        _analyzeMenu();
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image');
    }
  }

  Future<void> _analyzeMenu() async {
    if (_imageBytes == null) return;

    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final result = await geminiService.analyzeMenuImage(_imageBytes!);

      setState(() {
        _extractedMenu = result;
        _isScanning = false;

        // Auto-select random item
        if (result.items.isNotEmpty) {
          final randomIndex = DateTime.now().millisecond % result.items.length;
          _selectedItem = result.items[randomIndex];
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to analyze menu. Please try again.';
        _isScanning = false;
      });
    }
  }

  void _pickRandomItem() {
    if (_extractedMenu == null || _extractedMenu!.items.isEmpty) return;

    setState(() {
      final randomIndex =
          DateTime.now().millisecond % _extractedMenu!.items.length;
      _selectedItem = _extractedMenu!.items[randomIndex];
    });
  }

  void _reset() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _extractedMenu = null;
      _selectedItem = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVip = context.watch<SubscriptionProvider>().isVip;

    // Check VIP access
    if (!isVip) {
      return _buildVipRequired();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu Scanner'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_imageFile != null)
            IconButton(
              icon: const Icon(Iconsax.refresh),
              onPressed: _reset,
            ),
        ],
      ),
      body: SafeArea(
        child:
            _imageFile == null ? _buildUploadSection() : _buildResultSection(),
      ),
    );
  }

  Widget _buildVipRequired() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Iconsax.scan,
                  size: 64,
                  color: Colors.white,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(
                'VIP Feature',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Menu scanning uses AI to extract dishes from any restaurant menu. Upgrade to VIP to unlock this feature.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.crown, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Upgrade to VIP - \$5.99/mo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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

  Widget _buildUploadSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera option
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Iconsax.camera,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Take a Photo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Snap a picture of the menu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Gallery option
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.textLight.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.gallery, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    'Choose from Gallery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.magic_star, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI will analyze the menu and help you decide what to order!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Image.file(
                  _imageFile!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                if (_isScanning)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing menu...',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.warning_2, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // Selected item
          if (_selectedItem != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text(
                    '🎯',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedItem!.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedItem!.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _selectedItem!.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_selectedItem!.price != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedItem!.price!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (_selectedItem!.isVegetarian)
                        _buildTag('🥬 Vegetarian', Colors.green),
                      if (_selectedItem!.isVegan)
                        _buildTag('🌱 Vegan', Colors.green),
                      if (_selectedItem!.isSpicy)
                        _buildTag('🌶️ Spicy', Colors.red),
                    ],
                  ),
                ],
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 16),

            // Pick another button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickRandomItem,
                icon: const Icon(Iconsax.refresh),
                label: const Text('Pick Another'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],

          // Menu items list
          if (_extractedMenu != null && _extractedMenu!.items.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Items (${_extractedMenu!.items.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_extractedMenu!.cuisineType != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _extractedMenu!.cuisineType!,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_extractedMenu!.items.length, (index) {
              final item = _extractedMenu!.items[index];
              final isSelected = _selectedItem == item;

              return GestureDetector(
                onTap: () => setState(() => _selectedItem = item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (item.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.description!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (item.price != null)
                        Text(
                          item.price!,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: (index * 50).ms)
                  .slideX(begin: 0.1, end: 0);
            }),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
