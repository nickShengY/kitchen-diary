import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Export format option data
class ExportFormat {
  final String id;
  final String label;
  final String extension;
  final String icon;
  final String description;
  final Map<String, dynamic> settings;
  final bool isPremium;

  const ExportFormat({
    required this.id,
    required this.label,
    required this.extension,
    required this.icon,
    required this.description,
    required this.settings,
    this.isPremium = false,
  });

  factory ExportFormat.fromJson(String id, Map<String, dynamic> json) {
    return ExportFormat(
      id: id,
      label: json['label'] as String,
      extension: json['extension'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      settings: json['settings'] as Map<String, dynamic>,
      isPremium: json['premium'] as bool? ?? false,
    );
  }
}

/// Export options bottom sheet
class ExportOptionsSheet extends StatefulWidget {
  final List<ExportFormat> formats;
  final Function(ExportFormat format, Map<String, dynamic> settings)? onExport;

  const ExportOptionsSheet({
    super.key,
    required this.formats,
    this.onExport,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ExportFormat> formats,
    Function(ExportFormat format, Map<String, dynamic> settings)? onExport,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExportOptionsSheet(
        formats: formats,
        onExport: onExport,
      ),
    );
  }

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  ExportFormat? _selectedFormat;
  Map<String, dynamic> _currentSettings = {};

  @override
  void initState() {
    super.initState();
    if (widget.formats.isNotEmpty) {
      _selectedFormat = widget.formats.first;
      _currentSettings = Map.from(_selectedFormat!.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text('📻', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Text(
                      'Export Animation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Format selection
                    const Text(
                      'Choose Format',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...widget.formats.asMap().entries.map((entry) {
                      final format = entry.value;
                      final isSelected = _selectedFormat?.id == format.id;

                      return _FormatCard(
                        format: format,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedFormat = format;
                            _currentSettings = Map.from(format.settings);
                          });
                        },
                      )
                          .animate(
                              delay: Duration(milliseconds: entry.key * 50))
                          .fadeIn()
                          .slideX(begin: 0.05, end: 0);
                    }),

                    const SizedBox(height: 24),

                    // Settings for selected format
                    if (_selectedFormat != null) ...[
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettings(_selectedFormat!),
                    ],
                  ],
                ),
              ),

              // Export button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedFormat != null
                          ? () {
                              HapticFeedback.mediumImpact();
                              widget.onExport
                                  ?.call(_selectedFormat!, _currentSettings);
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedFormat?.icon ?? '📻',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Export as ${_selectedFormat?.label ?? 'File'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettings(ExportFormat format) {
    final settings = format.settings;
    final widgets = <Widget>[];

    // FPS setting
    if (settings.containsKey('fps')) {
      final fps = settings['fps'];
      final defaultFps = settings['defaultFps'];

      if (fps is List) {
        widgets.add(_SettingDropdown(
          label: 'Frame Rate',
          icon: Icons.speed,
          options: fps.map((f) => '$f fps').toList(),
          selectedIndex: fps.indexOf(_currentSettings['fps'] ?? defaultFps),
          onChanged: (index) {
            setState(() {
              _currentSettings['fps'] = fps[index];
            });
          },
        ));
      }
    }

    // Quality setting
    if (settings.containsKey('quality') && settings['quality'] is List) {
      final quality = settings['quality'] as List;
      final defaultQuality = settings['defaultQuality'];

      widgets.add(_SettingDropdown(
        label: 'Quality',
        icon: Icons.high_quality,
        options: quality.map((q) => q.toString().toUpperCase()).toList(),
        selectedIndex:
            quality.indexOf(_currentSettings['quality'] ?? defaultQuality),
        onChanged: (index) {
          setState(() {
            _currentSettings['quality'] = quality[index];
          });
        },
      ));
    }

    // Resolution setting
    if (settings.containsKey('resolution') && settings['resolution'] is List) {
      final resolution = settings['resolution'] as List;
      final defaultRes = settings['defaultResolution'];

      widgets.add(_SettingDropdown(
        label: 'Resolution',
        icon: Icons.photo_size_select_large,
        options: resolution.cast<String>(),
        selectedIndex:
            resolution.indexOf(_currentSettings['resolution'] ?? defaultRes),
        onChanged: (index) {
          setState(() {
            _currentSettings['resolution'] = resolution[index];
          });
        },
      ));
    }

    // Loop setting
    if (settings.containsKey('loop')) {
      widgets.add(_SettingSwitch(
        label: 'Loop Animation',
        icon: Icons.loop,
        value: _currentSettings['loop'] ?? settings['loop'],
        onChanged: (value) {
          setState(() {
            _currentSettings['loop'] = value;
          });
        },
      ));
    }

    // Include audio setting
    if (settings.containsKey('includeAudio')) {
      widgets.add(_SettingSwitch(
        label: 'Include Sound Effects',
        icon: Icons.volume_up,
        value: _currentSettings['includeAudio'] ?? settings['includeAudio'],
        onChanged: (value) {
          setState(() {
            _currentSettings['includeAudio'] = value;
          });
        },
      ));
    }

    // Transparency setting
    if (settings.containsKey('transparency')) {
      widgets.add(_SettingSwitch(
        label: 'Transparent Background',
        icon: Icons.layers_clear,
        value: _currentSettings['transparency'] ?? settings['transparency'],
        onChanged: (value) {
          setState(() {
            _currentSettings['transparency'] = value;
          });
        },
      ));
    }

    return Column(
      children: widgets
          .map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: w,
              ))
          .toList(),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final ExportFormat format;
  final bool isSelected;
  final VoidCallback? onTap;

  const _FormatCard({
    required this.format,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(format.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        format.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '.${format.extension}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (format.isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    format.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int>? onChanged;

  const _SettingDropdown({
    required this.label,
    required this.icon,
    required this.options,
    required this.selectedIndex,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButton<int>(
              value: selectedIndex >= 0 && selectedIndex < options.length
                  ? selectedIndex
                  : 0,
              isDense: true,
              underline: const SizedBox(),
              items: options.asMap().entries.map((e) {
                return DropdownMenuItem<int>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onChanged?.call(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingSwitch({
    required this.label,
    required this.icon,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
