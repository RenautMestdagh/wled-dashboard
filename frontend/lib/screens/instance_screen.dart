import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/instance.dart';
import '../services/api_service.dart';
import '../widgets/cct_slider.dart';
import '../widgets/colorpicker.dart';
import '../widgets/instance_modal.dart';

class InstanceScreen extends StatefulWidget {
  final WLEDInstance instance;
  final VoidCallback? onInstanceDeleted;

  const InstanceScreen({
    super.key,
    required this.instance,
    this.onInstanceDeleted,
  });

  @override
  State<InstanceScreen> createState() => _InstanceScreenState();
}

class _InstanceScreenState extends State<InstanceScreen> {
  String _instanceName = '';
  bool _instanceSupportsRGB = false;
  bool _instanceSupportsWhite = false;
  bool _instanceSupportsCCT = false;
  bool _isLoading = true;
  bool _isBackgroundLoading = false;
  Map<String, dynamic> _devicePresets = {};
  Map<String, dynamic> _deviceState = {};
  bool _power = false;
  double _brightness = 255;
  int? _activePresetId;
  List<List<double>> _colors = [
    [0, 0, 0],
    [0, 0, 0],
    [0, 0, 0],
  ];
  int _cctValue = 127; // Default CCT value
  final GlobalKey _moreButtonKey = GlobalKey();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _instanceName = widget.instance.name;
    _instanceSupportsRGB = widget.instance.supportsRGB;
    _instanceSupportsWhite = widget.instance.supportsWhite;
    _instanceSupportsCCT = widget.instance.supportsCCT;
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
      _instanceSupportsWhite = widget.instance.supportsWhite;
      _instanceSupportsCCT = widget.instance.supportsCCT;
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
    _power = _deviceState['on'] ?? false;
    _brightness = (_deviceState['bri'] ?? 128).toDouble();
    _activePresetId = _deviceState['ps'];

    if (_deviceState['seg'] != null && _deviceState['seg'] is List && _deviceState['seg'].isNotEmpty) {
      var segment = _deviceState['seg'][0];

      // Extract CCT value if available
      if (segment['cct'] != null) {
        _cctValue = segment['cct'];
      }

      // Extract colors if available
      if (segment['col'] != null && segment['col'] is List && segment['col'].isNotEmpty) {
        _colors = (segment['col'] as List).map<List<double>>((c) {
          return List<double>.from(c.map((value) => value.toDouble() / 255.0));
        }).toList();

        // Ensure white channel exists if device supports it
        if (_instanceSupportsWhite && _colors[0].length < 4) {
          _colors[0] = [..._colors[0], 0.0]; // Add white channel with 0 value
        }
      }
    }
  }

  Future<void> _togglePower() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final newPowerState = !_power;

    try {
      setState(() => _power = newPowerState);
      await apiService.updateDeviceState(widget.instance.id, {'on': newPowerState});
      _backgroundLoadDeviceData();
    } catch (e) {
      setState(() => _power = !newPowerState); // Revert on failure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to toggle power')),
      );
    }
  }

  // Updated brightness function with proper state management
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
      // Restore previous brightness on failure
      setState(() => _brightness = _deviceState['bri']?.toDouble() ?? 128);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update brightness')),
      );
    }
  }

  // Color management functions
  double _getRGBBrightness() {
    if (_colors[0].length < 3) return 0;
    return _colors[0].sublist(0, 3).reduce(max);
  }

  void _updateColor(Color color) {
    setState(() {
      double rgbBrightness = _getRGBBrightness();
      // Default to full brightness if current brightness is 0
      if (rgbBrightness <= 0) rgbBrightness = 1.0;

      // Create new list with updated RGB values while preserving white value
      List<double> newColor = [
        color.r * rgbBrightness,
        color.g * rgbBrightness,
        color.b * rgbBrightness,
      ];

      // Preserve white value if it exists
      if (_colors[0].length > 3) {
        newColor.add(_colors[0][3]);
      }

      _colors[0] = newColor;
    });
  }

  Future<void> _onColorChangeEnd(Color color) async {
    _updateColor(color);
    await _updateDeviceColors();
  }

  // RGB brightness slider function
  Future<void> _updateRGBBrightness(double value) async {
    setState(() {
      final maxVal = _colors[0].take(3).reduce((a, b) => a > b ? a : b);
      if (maxVal <= 0.001) {
        // If RGB values are essentially 0, set all channels to the new value
        _colors[0][0] = value;
        _colors[0][1] = value;
        _colors[0][2] = value;
      } else {
        // Scale RGB values proportionally
        final factor = value / maxVal;
        for (var i = 0; i < 3; i++) {
          _colors[0][i] = (_colors[0][i] * factor).clamp(0.0, 1.0);
        }
      }
    });

    await _updateDeviceColors();
  }

  // White channel slider function
  Future<void> _updateWhiteValue(double value) async {
    setState(() {
      if (_colors[0].length <= 3) {
        _colors[0] = [..._colors[0], value];
      } else {
        _colors[0][3] = value;
      }
    });

    await _updateDeviceColors();
  }

  // CCT slider function
  Future<void> _updateCCTValue(double value) async {
    final newCCT = value.toInt();
    setState(() => _cctValue = newCCT);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.updateDeviceState(widget.instance.id, {
        "on": true,
        'seg': {
          'cct': newCCT,
        },
      });
      _backgroundLoadDeviceData();
    } catch (e) {
      // Restore previous CCT value on failure
      final oldCCT = _deviceState['seg']?[0]?['cct'] ?? 127;
      setState(() => _cctValue = oldCCT);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update color temperature')),
        );
      }
    }
  }

  // Helper to update device with current color settings
  Future<void> _updateDeviceColors() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      // Convert all colors from 0-1 range to 0-255 integers for WLED
      List<List<int>> colorsForApi = _colors.map((color) {
        return color.map((value) => (value * 255).round().clamp(0, 255)).toList();
      }).toList();

      // WLED expects the color in segments
      await apiService.updateDeviceState(widget.instance.id, {
        "on": true,
        'seg': {
          'col': colorsForApi,
        },
      });

      // Refresh the device state to confirm the change
      _backgroundLoadDeviceData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update colors')),
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
                                  initialColor: Color.fromRGBO(
                                      (_colors[0][0] * 255).round(),
                                      (_colors[0][1] * 255).round(),
                                      (_colors[0][2] * 255).round(),
                                      1.0
                                  ),
                                  scaleFactor: 1.0/_getRGBBrightness().clamp(0.001, 1.0),
                                  onColorChanged: _updateColor,
                                  onColorChangeEnd: _onColorChangeEnd,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_instanceSupportsRGB && _instanceSupportsWhite) ...[
                          const SizedBox(height: 12),
                          Card(
                              elevation: 1,
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.colorize, color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              trackHeight: 3.0,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                            ),
                                            child: Slider(
                                              value: _getRGBBrightness(),
                                              min: 0,
                                              max: 1.0,
                                              label: (_getRGBBrightness() * 100).toStringAsFixed(0) + "%",
                                              onChanged: (value) {
                                                setState(() {
                                                  final maxVal = _colors[0].take(3).reduce((a, b) => a > b ? a : b);
                                                  if (maxVal <= 0.001) {
                                                    _colors[0][0] = value;
                                                    _colors[0][1] = value;
                                                    _colors[0][2] = value;
                                                  } else {
                                                    final factor = value / maxVal;
                                                    for (var i = 0; i < 3; i++) {
                                                      _colors[0][i] = (_colors[0][i] * factor).clamp(0, 1.0);
                                                    }
                                                  }
                                                });
                                              },
                                              onChangeEnd: _updateRGBBrightness,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.brightness_7, color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              trackHeight: 3.0,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                            ),
                                            child: Slider(
                                              value: _colors[0].length > 3 ? _colors[0][3].toDouble() : 0,
                                              min: 0,
                                              max: 1.0,
                                              label: (_colors[0].length > 3 ? _colors[0][3] * 100 : 0).toStringAsFixed(0) + "%",
                                              onChanged: (value) {
                                                setState(() {
                                                  if (_colors[0].length <= 3) {
                                                    _colors[0] = [..._colors[0], value];
                                                  } else {
                                                    _colors[0][3] = value;
                                                  }
                                                });
                                              },
                                              onChangeEnd: _updateWhiteValue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_instanceSupportsCCT) Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.thermostat, color: theme.colorScheme.primary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              trackHeight: 3.0,
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                              trackShape: CCTSliderTrackShape(),
                                            ),
                                            child: Slider(
                                              value: _cctValue.toDouble(),
                                              min: 0,
                                              max: 255,
                                              divisions: 255,
                                              label: _cctValue.toString(),
                                              onChanged: (value) {
                                                setState(() => _cctValue = value.toInt());
                                              },
                                              onChangeEnd: _updateCCTValue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                          ),
                        ],

                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 16.0),
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
