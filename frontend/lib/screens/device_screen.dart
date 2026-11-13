import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../l10n/app_localizations.dart';
import '../widgets/cct_track_shape.dart';
import '../widgets/color_wheel.dart';
import '../widgets/feedback.dart';
import '../widgets/readable_width.dart';
import '../widgets/scope.dart';
import 'device_dialog.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late Instance _instance = widget.instance;
  DeviceInfo? _info;
  List<DevicePreset> _presets = const [];
  ApiException? _error;
  bool _loading = true;

  // What the controls show; changed while dragging, sent to the device when a drag ends
  bool _on = false;
  double _brightness = 0;
  List<int> _color = const [255, 255, 255];
  int _cct = 127;
  int _preset = -1;

  Store get _store => Scope.read<Store>(context);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = _store.api;
      final id = _instance.id;
      final results = await Future.wait<Object>([api.deviceInfo(id), api.deviceState(id), api.devicePresets(id)]);
      _info = results[0] as DeviceInfo;
      _show(DeviceState.fromJson(results[1] as Json));
      _presets = results[2] as List<DevicePreset>;
    } on ApiException catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(DeviceState state) {
    _on = state.on;
    _brightness = state.brightness.toDouble();
    _preset = state.preset;
    _cct = state.cct ?? _cct;
    if (state.color.length >= 3) _color = state.color;
  }

  Future<void> _send(Json state) async {
    try {
      await _store.api.setDeviceState(_instance.id, state);
      unawaited(_store.loadState(_instance.id));
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e);
      await _load();
    }
  }

  Future<void> _setPower(bool on) async {
    setState(() => _on = on);
    try {
      await _store.setPower(_instance.id, on);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _on = !on);
      showError(context, e);
    }
  }

  Future<void> _applyDevicePreset(int number) async {
    setState(() {
      _preset = number;
      _on = true;
    });
    await _send({'ps': number});
  }

  int get _rgbLevel => _color.take(3).reduce(math.max);

  void _setColor(List<int> color) {
    setState(() {
      _color = color;
      _on = true;
    });
    unawaited(
      _send({
        'on': true,
        'seg': {
          'col': [color],
          'fx': 0,
        },
      }),
    );
  }

  /// The hue of [color] with its brightest RGB channel at [level] (0–255), keeping the current white channel.
  List<int> _withLevel(Color color, int level) {
    final channels = [color.r, color.g, color.b];
    final brightest = channels.reduce(math.max);
    final rgb = brightest == 0 ? [level, level, level] : [for (final c in channels) (c / brightest * level).round()];
    return [...rgb, ..._color.skip(3)];
  }

  Future<void> _edit() async {
    if (await showDeviceDialog(context, _instance) && mounted) {
      setState(() => _instance = _store.instances.firstWhere((instance) => instance.id == _instance.id));
      await _load();
    }
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final confirmed = await confirm(
      context,
      title: s.deleteDeviceTitle,
      message: s.deleteDeviceMessage(_instance.label),
      action: s.delete,
    );
    if (!confirmed || !mounted) return;
    try {
      await _store.deleteInstance(_instance.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final info = _info;

    return Scaffold(
      appBar: AppBar(
        title: Text(_instance.label),
        actions: [
          if (info != null && _error == null) Switch(value: _on, onChanged: _setPower),
          PopupMenuButton<VoidCallback>(
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _edit,
                child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(s.editDevice)),
              ),
              PopupMenuItem(
                value: _delete,
                child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(s.deleteDeviceTitle)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: switch ((_loading, _error, info)) {
          (true, _, _) => const Center(child: CircularProgressIndicator()),
          (_, final error?, _) => MessageView(
            icon: Icons.wifi_off,
            title: s.notReachable(_instance.ip),
            message: errorText(s, error),
            action: FilledButton.tonal(onPressed: _load, child: Text(s.retry)),
          ),
          (_, _, final info?) => ReadableWidth(
            child: RefreshIndicator(onRefresh: _load, child: _controls(info)),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _controls(DeviceInfo info) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final rgb = Color.fromARGB(255, _color[0], _color[1], _color[2]);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SliderCard(
          icon: Icons.brightness_6,
          label: s.brightness,
          value: _brightness,
          onChanged: (value) => setState(() => _brightness = value),
          onChangeEnd: (value) {
            setState(() => _on = true);
            unawaited(_send({'on': true, 'bri': value.round()}));
          },
        ),
        if (info.hasRgb) ...[
          _Section(s.color),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ColorWheel(
                  label: s.color,
                  color: rgb,
                  onChangeEnd: (color) => _setColor(_withLevel(color, _rgbLevel == 0 ? 255 : _rgbLevel)),
                ),
              ),
            ),
          ),
        ],
        if (info.hasRgb && info.hasWhite) ...[
          const SizedBox(height: 8),
          _SliderCard(
            icon: Icons.palette_outlined,
            label: s.colorLevel,
            value: _rgbLevel.toDouble(),
            onChanged: (value) => setState(() => _color = _withLevel(rgb, value.round())),
            onChangeEnd: (value) => _setColor(_withLevel(rgb, value.round())),
          ),
          const SizedBox(height: 8),
          _SliderCard(
            icon: Icons.light_mode_outlined,
            label: s.white,
            value: _color.length > 3 ? _color[3].toDouble() : 0,
            onChanged: (value) => setState(() => _color = [..._color.take(3), value.round()]),
            onChangeEnd: (value) => _setColor([..._color.take(3), value.round()]),
          ),
        ],
        if (info.hasCct) ...[
          const SizedBox(height: 8),
          _SliderCard(
            icon: Icons.thermostat,
            label: s.colorTemperature,
            value: _cct.toDouble(),
            trackShape: const CctTrackShape(),
            onChanged: (value) => setState(() => _cct = value.round()),
            onChangeEnd: (value) => unawaited(
              _send({
                'on': true,
                'seg': {'cct': value.round()},
              }),
            ),
          ),
        ],
        _Section(s.wledPresets),
        if (_presets.isEmpty)
          Text(s.noDevicePresets, style: theme.textTheme.bodyMedium)
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final preset in _presets)
                  ListTile(
                    title: Text(preset.name),
                    selected: preset.number == _preset,
                    trailing: Icon(preset.number == _preset ? Icons.check_circle : Icons.play_arrow),
                    onTap: () => _applyDevicePreset(preset.number),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.trackShape,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final SliderTrackShape? trackShape;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Tooltip(
              message: label,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(trackShape: trackShape),
                child: Slider(
                  value: value.clamp(0, 255),
                  max: 255,
                  label: value.round().toString(),
                  semanticFormatterCallback: (value) => '$label ${value.round()}',
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
