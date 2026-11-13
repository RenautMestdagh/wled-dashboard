import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/readable_width.dart';
import '../widgets/scope.dart';
import 'device_dialog.dart';
import 'devices_view.dart';
import 'preset_editor_screen.dart';
import 'presets_view.dart';
import 'reorder_screen.dart';
import 'schedule_editor_screen.dart';
import 'schedules_view.dart';
import 'settings_view.dart';

/// The one Scaffold of the main screens: a navigation bar on phones, a navigation rail on wider screens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  bool _discovering = false;

  Future<void> _toggleAll() async {
    final s = S.of(context);
    final failed = await context.store.toggleAll();
    if (failed.isNotEmpty && mounted) {
      showMessage(context, s.devicesDidNotAnswer(failed.map((instance) => instance.label).join(', ')));
    }
  }

  Future<void> _discover() async {
    final s = S.of(context);
    setState(() => _discovering = true);
    try {
      final added = await context.store.discover();
      if (mounted) showMessage(context, s.devicesFound(added.length));
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.store;
    final connected = store.isConnected;

    final tabs = [
      _Tab(
        icon: Icons.palette_outlined,
        selectedIcon: Icons.palette,
        label: s.presets,
        body: const PresetsView(),
        actions: [
          if (store.presets.length > 1)
            IconButton(
              tooltip: s.reorder,
              icon: const Icon(Icons.reorder),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReorderScreen(
                    title: s.reorderPresets,
                    items: store.presets,
                    label: (preset) => preset.name,
                    onSave: store.reorderPresets,
                  ),
                ),
              ),
            ),
        ],
        fab: FloatingActionButton(
          tooltip: s.newPreset,
          onPressed: () => openPresetEditor(context),
          child: const Icon(Icons.add),
        ),
      ),
      _Tab(
        icon: Icons.lightbulb_outline,
        selectedIcon: Icons.lightbulb,
        label: s.devices,
        body: const DevicesView(),
        actions: [
          if (_discovering)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(tooltip: s.findDevices, icon: const Icon(Icons.travel_explore), onPressed: _discover),
          if (store.instances.length > 1)
            IconButton(
              tooltip: s.reorder,
              icon: const Icon(Icons.reorder),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ReorderScreen(
                    title: s.reorderDevices,
                    items: store.instances,
                    label: (instance) => instance.label,
                    onSave: store.reorderInstances,
                  ),
                ),
              ),
            ),
          if (store.instances.isNotEmpty)
            IconButton(
              tooltip: store.anyOn ? s.allOff : s.allOn,
              isSelected: store.anyOn,
              icon: const Icon(Icons.power_settings_new),
              onPressed: _toggleAll,
            ),
        ],
        fab: FloatingActionButton(
          tooltip: s.addDevice,
          onPressed: () => showDeviceDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
      _Tab(
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule,
        label: s.schedules,
        body: const SchedulesView(),
        fab: FloatingActionButton(
          tooltip: s.newSchedule,
          onPressed: () => openScheduleEditor(context),
          child: const Icon(Icons.add),
        ),
      ),
      _Tab(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: s.settings, body: const SettingsView()),
    ];
    final tab = tabs[_index];
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(title: Text(tab.label), actions: connected ? tab.actions : null),
      body: SafeArea(
        child: Row(
          children: [
            if (wide) ...[
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (index) => setState(() => _index = index),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final tab in tabs)
                    NavigationRailDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: Text(tab.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [for (final tab in tabs) ReadableWidth(child: tab.body)],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: connected ? tab.fab : null,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: [
                for (final tab in tabs)
                  NavigationDestination(icon: Icon(tab.icon), selectedIcon: Icon(tab.selectedIcon), label: tab.label),
              ],
            ),
    );
  }
}

class _Tab {
  const _Tab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.body,
    this.actions = const [],
    this.fab,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget body;
  final List<Widget> actions;
  final Widget? fab;
}
