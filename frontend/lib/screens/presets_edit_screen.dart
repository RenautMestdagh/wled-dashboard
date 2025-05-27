import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/preset.dart';
import '../models/instance.dart';
import '../services/api_service.dart';

class PresetEditScreen extends StatefulWidget {
  final Preset? preset;

  const PresetEditScreen({super.key, this.preset});

  @override
  State<PresetEditScreen> createState() => _PresetEditScreenState();
}

class _PresetEditScreenState extends State<PresetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final Map<int, bool> _instanceSelected = {};
  final Map<int, dynamic> _instancePresets = {};
  final Map<int, Map<String, dynamic>> _availablePresets = {};
  final Map<int, dynamic> _currentDevicePresets = {};
  final Map<int, bool> _useCurrentState = {};
  final Map<int, Map<String, dynamic>> _oldStateJson = {};
  final Map<int, Map<String, dynamic>> _currentStateJson = {}; // Store full state JSON
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isInitializing = true);

    try {
      // If editing an existing preset, load its instances
      if (widget.preset != null) {
        await _loadPresetInstances();
      }

      // Load available presets for all instances
      await _loadAvailablePresets();

      // Load current active preset for each instance
      await _loadCurrentDeviceStates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _loadPresetInstances() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      // Get detailed information about this preset
      final presetDetails = await apiService.getPresetDetails(widget.preset!.id);

      // Set up the selected instances based on preset details
      for (var instance in presetDetails['instances']) {
        final instanceId = instance['instance_id'];
        _instanceSelected[instanceId] = true;

        // Try parsing instance['instance_preset'] to int
        final parsedPreset = int.tryParse(instance['instance_preset'].toString());

        if (parsedPreset != null) {
          // If parsing succeeds, store the preset setting as an integer
          _instancePresets[instanceId] = parsedPreset;
          _useCurrentState[instanceId] = false;
        } else {
          // If parsing fails, assume it's a current state value
          _oldStateJson[instanceId] = json.decode(instance['instance_preset'] as String) as Map<String, dynamic>;
          _useCurrentState[instanceId] = true;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadAvailablePresets() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    for (var instance in apiService.instances) {
      try {
        final presets = await apiService.getDevicePresets(instance.id);
        // Filter out empty presets
        final nonEmptyPresets = Map<String, dynamic>.fromEntries(presets.entries.where((entry) => entry.value != null && entry.value is Map && (entry.value as Map).isNotEmpty));

        if (mounted) {
          setState(() {
            _availablePresets[instance.id] = nonEmptyPresets;
          });
        }
      } catch (e) {
        print('Could not load presets for ${instance.name}: ${e.toString()}');
      }
    }
  }

  Future<void> _loadCurrentDeviceStates() async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    for (var instance in apiService.instances) {

      try {
        final state = await apiService.getDeviceState(instance.id);

        if (mounted) {
          setState(() {
            // Store the full state JSON
            _currentStateJson[instance.id] = Map<String, dynamic>.from(state);

            // Extract preset ID if available
            if (state.containsKey('ps')) {
              int presetId = state['ps'];
              _currentDevicePresets[instance.id] = presetId;
            }

            // Initialize useCurrentState to false for all instances
            _useCurrentState.putIfAbsent(instance.id, () => true);
          });
        }
      } catch (e) {
        print('Could not get current state for ${instance.name}: ${e.toString()}');
      }
    }
  }

  void _toggleInstanceSelection(WLEDInstance instance) {
    setState(() {
      // Toggle selection state
      _instanceSelected[instance.id] = !(_instanceSelected[instance.id] ?? false);

      // Initialize useCurrentState to false if not already set
      _useCurrentState.putIfAbsent(instance.id, () => true);
    });
  }

  void _toggleUseCurrentState(int instanceId, bool value) {
    setState(() {
      _useCurrentState[instanceId] = value;

      // If we're using the current state, store the full state JSON
      if (value && _currentStateJson.containsKey(instanceId)) {
        _instancePresets[instanceId] = _currentStateJson[instanceId];
      } else if (!value && _currentDevicePresets.containsKey(instanceId)) {
        // If unchecking, revert to using preset ID
        _instancePresets[instanceId] = _currentDevicePresets[instanceId];
        _oldStateJson.remove(instanceId);
      }
    });
  }

  void _updateInstancePreset(int instanceId, dynamic preset) {
    setState(() {
      _instancePresets[instanceId] = preset;
    });
  }

  List<DropdownMenuItem<dynamic>> _buildPresetItems(int instanceId) {
    final presets = _availablePresets[instanceId];
    final List<DropdownMenuItem<dynamic>> items = [];
    final Set<int> addedValues = {};

    if (presets != null && presets.isNotEmpty) {
      presets.forEach((key, value) {
        if (int.tryParse(key) != null) {
          final presetNumber = int.parse(key);
          if (presetNumber > 0 && !addedValues.contains(presetNumber)) {
            final presetName = value is Map && value['n'] != null ? value['n'] : 'Preset $presetNumber';

            items.add(DropdownMenuItem<int>(
              value: presetNumber,
              child: Text(presetName),
            ));

            addedValues.add(presetNumber);
          }
        }
      });
    }

    // Sort items by preset number
    items.sort((a, b) => (a.value as int).compareTo(b.value as int));

    return items;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePreset() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure at least one instance is selected
    final selectedInstanceIds = _instanceSelected.entries.where((entry) => entry.value).map((entry) => entry.key).toList();

    if (selectedInstanceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one instance')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final apiService = Provider.of<ApiService>(context, listen: false);

    // Build the instances array for the API request
    final instanceConfigs = selectedInstanceIds.map((instanceId) {

      final preset = _oldStateJson[instanceId] ??
          _instancePresets[instanceId] ??
          (_currentStateJson[instanceId]!['ps']! == -1
              ? _currentStateJson[instanceId] // If 'ps' is "-1", use _currentStateJson[instanceId]
              : _currentStateJson[instanceId]!['ps']); // Otherwise, use 'ps'


      return {
        'instance_id': instanceId,
        'instance_preset': preset,
      };
    }).toList();

    try {
      if (widget.preset == null) {
        // Create new preset
        await apiService.createPreset(_nameController.text, instanceConfigs);
      } else {
        // Update existing preset
        await apiService.updatePreset(widget.preset!.id, _nameController.text, instanceConfigs);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is handled by ApiService and shown via a SnackBar
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final theme = Theme.of(context);
    final instances = apiService.instances;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'Create Preset' : 'Edit Preset'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Preset Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Instance Settings', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (instances.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No instances available'),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: instances.map((instance) => _buildInstanceItem(instance, theme)).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.save),
        label: Text(widget.preset == null ? 'Create' : 'Save'),
        onPressed: _isLoading ? null : _savePreset,
      ),
    );
  }

  Widget _buildInstanceItem(WLEDInstance instance, ThemeData theme) {
    // Check if this instance has any presets
    final hasPresets = _availablePresets.containsKey(instance.id) && _availablePresets[instance.id]!.isNotEmpty;

    final isSelected = _instanceSelected[instance.id] ?? false;
    final useCurrentState = _useCurrentState[instance.id] ?? false;

    // If the instance is enabled, build preset items
    final presetItems = hasPresets ? _buildPresetItems(instance.id) : <DropdownMenuItem<dynamic>>[];

    // Get current preset value for dropdown (only used if not using current state)

    dynamic presetValue = _currentDevicePresets[instance.id];
    // If preset is -1, use first preset if available
    if (presetValue == -1 && presetItems.isNotEmpty) {
      presetValue = presetItems.first.value;
    }

    // if editing
    if(widget.preset != null) {
      presetValue = _instancePresets[instance.id];
    }

    // Make sure we have a valid preset selection that exists in the dropdown
    final safeValue = presetItems.any((item) => item.value == presetValue) ? presetValue : (presetItems.isNotEmpty ? presetItems.first.value : 1);

    return Column(
      children: [
        // Only show the switch initially, with default off
        SwitchListTile(
          title: Text(instance.name == '' ? 'WLED' : instance.name, style: theme.textTheme.bodyLarge),
          value: isSelected,
          onChanged: (_) => _toggleInstanceSelection(instance),
          activeColor: theme.colorScheme.primary,
        ),

        // Only if instance is selected, show the "Use current state" checkbox
        if (isSelected)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: CheckboxListTile(
                      title: const Text('Use current state'),
                      value: !hasPresets ? true : useCurrentState,
                      onChanged: !hasPresets
                          ? null
                          : (value) {
                        if (value != null) {
                          _toggleUseCurrentState(instance.id, value);
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )

              ),
              if (_oldStateJson[instance.id] != null )
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    direction: Axis.horizontal,  // Default to row layout
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 10,
                    spacing: 16,
                    children: [
                      // Text (does not wrap, stays in a single line)
                      Padding(
                        padding: const EdgeInsets.only(right: 0.0),
                        child: Text(
                          'This preset is using an old state.',
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          overflow: TextOverflow.ellipsis,  // Show "..." if text overflows
                        ),
                      ),
                      // Button (stays in row if space allows, wraps below if not)
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _oldStateJson.remove(instance.id);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          side: BorderSide(color: theme.colorScheme.primary), // Border color
                          foregroundColor: theme.colorScheme.primary, // Text + ripple color
                        ),
                        child: Text(
                          'Use Current State',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),

                    ],
                  )
                ),
            ],
          ),

        // Only show dropdown if:
        // 1. Instance is selected
        // 2. Use current state is NOT checked
        // 3. Instance has presets
        if (isSelected && !useCurrentState && hasPresets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButtonFormField<dynamic>(
              value: safeValue,
              items: presetItems.cast<DropdownMenuItem<dynamic>>(),
              onChanged: (value) {
                if (value != null) {
                  _updateInstancePreset(instance.id, value);
                }
              },
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                isDense: true,
              ),
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.primary,
              ),
              dropdownColor: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 300,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

        Divider(
          height: 20,
          indent: 10,
          endIndent: 10,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
      ],
    );
  }
}
