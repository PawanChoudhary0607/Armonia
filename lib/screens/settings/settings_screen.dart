// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:armonia/core/theme/app_colors.dart';
import 'package:armonia/core/theme/app_typography.dart';
import 'package:armonia/providers/settings_provider.dart';

/// Settings screen — Theme and Accent Color are fully functional in Phase 1.
/// Audio, notification, and storage settings arrive in Phase 9.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.darkBgBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.darkTextPrimary,
        ),
        title: Text(
          'Settings',
          style: AppTypography.titleLg.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── APPEARANCE ──────────────────────────────────────────────────
          _SectionLabel('APPEARANCE'),
          _SettingsGroup(
            children: [
              _SettingsNavRow(
                label: 'Theme',
                value: _themeLabel(settings.themeMode),
                onTap: () => _showThemePicker(context, ref, settings),
              ),
              const _Divider(),
              _SettingsNavRow(
                label: 'Accent Color',
                trailing: _ColorDot(color: settings.accentColor),
                onTap: () =>
                    _showAccentPicker(context, notifier, settings),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── AUDIO ───────────────────────────────────────────────────────
          _SectionLabel('AUDIO'),
          _SettingsGroup(
            children: [
              _SettingsNavRow(
                label: 'Streaming Quality',
                value: _qualityLabel(settings.streamingQuality),
                onTap: () => _showQualityPicker(
                  context,
                  title: 'Streaming Quality',
                  current: settings.streamingQuality,
                  onSelect: notifier.setStreamingQuality,
                ),
              ),
              const _Divider(),
              _SettingsNavRow(
                label: 'Download Quality',
                value: _qualityLabel(settings.downloadQuality),
                onTap: () => _showQualityPicker(
                  context,
                  title: 'Download Quality',
                  current: settings.downloadQuality,
                  onSelect: notifier.setDownloadQuality,
                ),
              ),
              const _Divider(),
              _SettingsNavRow(
                label: 'Crossfade',
                value: settings.crossfadeSeconds == 0
                    ? 'Off'
                    : '${settings.crossfadeSeconds}s',
                onTap: () =>
                    _showCrossfadePicker(context, notifier, settings),
              ),
              const _Divider(),
              _SettingsToggleRow(
                label: 'Data Saver',
                value: settings.dataSaverEnabled,
                onChanged: (_) => notifier.toggleDataSaver(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── NOTIFICATIONS ───────────────────────────────────────────────
          _SectionLabel('NOTIFICATIONS'),
          _SettingsGroup(
            children: [
              _SettingsToggleRow(
                label: 'Streak Reminders',
                value: settings.streakNotificationsEnabled,
                onChanged: (_) => notifier.toggleStreakNotifications(),
              ),
              const _Divider(),
              _SettingsToggleRow(
                label: 'Badge Unlocked',
                value: settings.badgeNotificationsEnabled,
                onChanged: (_) => notifier.toggleBadgeNotifications(),
              ),
              const _Divider(),
              _SettingsToggleRow(
                label: 'Weekly Recap',
                value: settings.recapNotificationsEnabled,
                onChanged: (_) => notifier.toggleRecapNotifications(),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── ABOUT ────────────────────────────────────────────────────────
          _SectionLabel('ABOUT'),
          _SettingsGroup(
            children: [
              _SettingsReadOnlyRow(
                label: 'Version',
                value: 'Armonia 1.0.0',
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  String _qualityLabel(String q) {
    switch (q) {
      case 'high':
        return 'High';
      case 'normal':
        return 'Normal';
      case 'low':
        return 'Low';
      default:
        return 'High';
    }
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _ThemePickerSheet(
        current: settings.themeMode,
        onSelect: (mode) {
          ref.read(settingsProvider.notifier).setThemeMode(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAccentPicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _AccentPickerSheet(
        current: settings.accentColor,
        presets: notifier.accentPresets,
        names: notifier.accentPresetNames,
        onSelect: notifier.setAccentColor,
      ),
    );
  }

  void _showQualityPicker(
    BuildContext context, {
    required String title,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _QualityPickerSheet(
        title: title,
        current: current,
        onSelect: (q) {
          onSelect(q);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCrossfadePicker(
    BuildContext context,
    SettingsNotifier notifier,
    SettingsState settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _CrossfadeSheet(
        value: settings.crossfadeSeconds,
        onChanged: notifier.setCrossfadeSeconds,
      ),
    );
  }
}

// ── Shared layout pieces ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkBgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorderSubtle),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: AppColors.darkBorderSubtle,
      indent: 20,
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  const _SettingsNavRow({
    required this.label,
    this.value,
    this.trailing,
    required this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            if (trailing != null) trailing!,
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.darkTextTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsReadOnlyRow extends StatelessWidget {
  const _SettingsReadOnlyRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── Bottom sheets ───────────────────────────────────────────────────────────

class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet({
    required this.current,
    required this.onSelect,
  });

  final ThemeMode current;
  final ValueChanged<ThemeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 20),
            Text(
              'Theme',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in [
              (ThemeMode.dark, 'Dark'),
              (ThemeMode.light, 'Light'),
              (ThemeMode.system, 'System (Auto)'),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  entry.$2,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                trailing: current == entry.$1
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => onSelect(entry.$1),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccentPickerSheet extends StatefulWidget {
  const _AccentPickerSheet({
    required this.current,
    required this.presets,
    required this.names,
    required this.onSelect,
  });

  final Color current;
  final List<Color> presets;
  final List<String> names;
  final ValueChanged<Color> onSelect;

  @override
  State<_AccentPickerSheet> createState() => _AccentPickerSheetState();
}

class _AccentPickerSheetState extends State<_AccentPickerSheet> {
  late Color _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 20),
            Text(
              'Accent Color',
              style: AppTypography.titleLg.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Propagates to buttons, sliders, and indicators across the app.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(widget.presets.length, (i) {
                final Color c = widget.presets[i];
                final bool isSelected =
                    c.toARGB32() == _selected.toARGB32();
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = c);
                    widget.onSelect(c);
                  },
                  child: Tooltip(
                    message: widget.names[i],
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityPickerSheet extends StatelessWidget {
  const _QualityPickerSheet({
    required this.title,
    required this.current,
    required this.onSelect,
  });

  final String title;
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.titleLg.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in [
              ('high', 'High', '~5 MB/min'),
              ('normal', 'Normal', '~3 MB/min'),
              ('low', 'Low', '~1 MB/min'),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  entry.$2,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                subtitle: Text(
                  entry.$3,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                trailing: current == entry.$1
                    ? Icon(Icons.check_rounded, color: accent)
                    : null,
                onTap: () => onSelect(entry.$1),
              ),
          ],
        ),
      ),
    );
  }
}

class _CrossfadeSheet extends StatefulWidget {
  const _CrossfadeSheet({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_CrossfadeSheet> createState() => _CrossfadeSheetState();
}

class _CrossfadeSheetState extends State<_CrossfadeSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    final int rounded = _value.round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Crossfade',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ),
                Text(
                  rounded == 0 ? 'Off' : '${rounded}s',
                  style: AppTypography.monoLg.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _value,
              min: 0,
              max: 12,
              divisions: 12,
              onChanged: (v) {
                setState(() => _value = v);
                widget.onChanged(v.round());
              },
            ),
            Text(
              rounded == 0
                  ? 'No crossfade — tracks play back to back.'
                  : 'Songs will overlap ${rounded}s before the current track ends.',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.darkTextTertiary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
