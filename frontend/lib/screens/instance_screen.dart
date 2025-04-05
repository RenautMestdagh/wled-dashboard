import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/instance.dart';
import '../services/api_service.dart';
import '../widgets/colorpicker.dart';
import '../widgets/instance_modal.dart';

class InstanceScreen extends StatefulWidget {
  final WLEDInstance instance;
  final VoidCallback? onInstanceDeleted;

  const InstanceScreen({
    super.key,
    required this.instance,
    this.onInstanceDeleted, // Add this parameter
  });

  @override
  State<InstanceScreen> createState() => _InstanceScreenState();
}

class _InstanceScreenState extends State<InstanceScreen> {
  String _instanceName = '';
  bool _instanceSupportsRGB = false;
  bool _isLoading = true;
  bool _isBackgroundLoading = false;
  Map<String, dynamic> _devicePresets = {};
  Map<String, dynamic> _deviceState = {};
  bool _power = false;
  double _brightness = 255;
  int? _activePresetId;
  List<List<int>> _colors = [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0],
  ];
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _instanceName = widget.instance.name;
    _instanceSupportsRGB = widget.instance.supportsRGB;
    _loadDeviceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now listening to changes
    final apiService = Provider.of<ApiService>(context);
    final cachedState = apiService.getDeviceStateCached(widget.instance.id);
    if (cachedState != null) {
      updateDeviceState(cachedState);
    }
  }

  Future<void> _loadDeviceData() async {
    setState(() => _isLoading = true);
    try {
      await _fetchDeviceInfo();
      await _fetchDeviceData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _backgroundLoadDeviceData() async {
    if (_isBackgroundLoading) return;
    setState(() => _isBackgroundLoading = true);
    try {
      await _fetchDeviceData();
    } finally {
      if (mounted) setState(() => _isBackgroundLoading = false);
    }
  }

  Future<void> _fetchDeviceInfo() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    await apiService.getDeviceInfo(widget.instance.id);

    setState(() {
      _instanceName = widget.instance.name;
      _instanceSupportsRGB = widget.instance.supportsRGB;
    });

    _devicePresets = await apiService.getDevicePresets(widget.instance.id);
  }

  Future<void> _fetchDeviceData() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final deviceState = await apiService.getDeviceState(widget.instance.id);

      if (mounted) {
        setState(() {
          _applyDeviceState(deviceState);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load device data')),
        );
      }
    }
  }

  void updateDeviceState(Map<String, dynamic> newState) {
    if (!mounted) return;

    setState(() {
      _applyDeviceState(newState);
    });
  }

  void _applyDeviceState(Map<String, dynamic> state) {
    _deviceState = state;
    _power = _deviceState['on'] ?? true;
    _brightness = (_deviceState['bri'] ?? 128).toDouble();
    _activePresetId = _deviceState['ps'];

    if (_deviceState['seg'] != null && _deviceState['seg'] is List && _deviceState['seg'].isNotEmpty) {
      var segment = _deviceState['seg'][0];
      if (segment['col'] != null && segment['col'] is List && segment['col'].isNotEmpty) {
        _colors = (segment['col'] as List).map<List<int>>((c) => List<int>.from(c)).toList();
      }
    }
  }

  Future<void> _togglePower() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      setState(() => _power = !_power);
      await apiService.updateDeviceState(widget.instance.id, {'on': _power});
      _backgroundLoadDeviceData();
    } catch (e) {
      setState(() => _power = !_power);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to toggle power')),
      );
    }
  }

  void _updateBrightness(double value) => setState(() => _brightness = value);

  Future<void> _onBrightnessChangeEnd(double value) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.updateDeviceState(
          widget.instance.id,
          {
            "on": true,
            'bri': value.toInt()
          }
      );
      _backgroundLoadDeviceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update brightness')),
      );
    }
  }

  void _updateColor(Color color) {
    setState(() {
      _colors[0] = [
        (color.r * 255).round(),
        (color.g * 255).round(),
        (color.b * 255).round(),
      ];
    });
  }

  Future<void> _onColorChangeEnd(Color color) async {
    _updateColor(color);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // WLED expects the color in segments
      await apiService.updateDeviceState(widget.instance.id, {
        "on": true,
        'seg': {
          'col': _colors,
          "fx": 0,
        },
      });

      // Refresh the device state to confirm the change
      _backgroundLoadDeviceData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update color')),
        );
      }
    }
  }

  Future<void> _applyDevicePreset(String presetId) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final presetIdInt = int.parse(presetId);
      setState(() => _activePresetId = presetIdInt);
      await apiService.updateDeviceState(widget.instance.id, {'ps': presetIdInt});
      Future.delayed(Duration(milliseconds: 500), () => _backgroundLoadDeviceData());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply preset')),
      );
    }
  }

  Future<void> _showEditModal() async {
    final saved = await showDialog(
      context: context,
      builder: (context) => InstanceModal(instance: widget.instance),
    );
    if (saved) _loadDeviceData();
  }

  Future<void> _showOptionsMenu(BuildContext context) async {
    final renderBox = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    const menuWidth = 180.0;

    final result = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx - menuWidth + renderBox!.size.width,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'refresh',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.refresh_rounded, size: 22),
            title: Text('Refresh Instance'),
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.edit, size: 22),
            title: Text('Edit Instance'),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.delete, size: 22, color: Colors.red),
            title: Text('Delete Instance', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
      elevation: 4,
    );

    if (result == 'edit') {
      await _showEditModal();
    } else if (result == 'delete') {
      await _confirmDelete();
    } else if (result == 'refresh') {
      _loadDeviceData();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Instance?'),
        content: const Text('This will remove the instance permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.deleteInstance(widget.instance.id);

        // Call the callback if it exists
        if (widget.onInstanceDeleted != null) {
          widget.onInstanceDeleted!();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete instance')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_instanceName == '' ? 'WLED' : _instanceName),
        actions: [
          IconButton(
            icon: Icon(Icons.power_settings_new, color: _power ? Colors.green : Colors.red),
            onPressed: _togglePower,
          ),
          IconButton(
            key: _moreButtonKey,
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _loadDeviceData,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // Brightness slider
                              Card(
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.brightness_6, color: theme.colorScheme.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 3.0,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                          ),
                                          child: Slider(
                                            value: _brightness,
                                            min: 0,
                                            max: 255,
                                            divisions: 255,
                                            label: _brightness.round().toString(),
                                            onChanged: _updateBrightness,
                                            onChangeEnd: _onBrightnessChangeEnd,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_instanceSupportsRGB) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                                  child: Text(
                                    'Color',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: ColorPicker(
                                        initialColor: Color.fromARGB(255, _colors[0][0], _colors[0][1], _colors[0][2]),
                                        onColorChanged: _updateColor,
                                        onColorChangeEnd: _onColorChangeEnd,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              Padding(
                                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                                child: Text(
                                  'Presets',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (_devicePresets.isEmpty)
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('No presets found on this device'),
                                  ),
                                )
                              else
                                ..._devicePresets.entries.where((e) => e.value['n'] != null).map((entry) {
                                  final presetId = int.tryParse(entry.key);
                                  final isActive = presetId == _activePresetId;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    elevation: isActive ? 2 : 1,
                                    color: isActive ? theme.colorScheme.primaryContainer : null,
                                    child: Material(
                                      borderRadius: BorderRadius.circular(12), // Same border radius as ListTile
                                      color: Colors.transparent, // Make sure background is transparent
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12), // Same border radius for ripple
                                        onTap: () => _applyDevicePreset(entry.key),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          title: Text(
                                            entry.value['n'] ?? 'Untitled',
                                            style: TextStyle(
                                              color: isActive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          trailing: Icon(
                                            isActive ? Icons.check_circle : Icons.play_arrow,
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ),
                                    )
                                  );
                                }).toList(),
                              // Add an empty spacer at the bottom if needed
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
