import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/instance.dart';

class InstanceModal extends StatefulWidget {
  final WLEDInstance? instance;
  final Function(int)? onInstanceCreated; // Add this callback

  const InstanceModal({
    super.key,
    this.instance,
    this.onInstanceCreated, // Add this parameter
  });

  @override
  State<InstanceModal> createState() => _InstanceModalState();
}

class _InstanceModalState extends State<InstanceModal> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.instance != null) {
      _ipController.text = widget.instance!.ip;
      _nameController.text = widget.instance!.name;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final isEditing = widget.instance != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth > 600 ? 500 : screenWidth - 40,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit WLED Instance' : 'Add WLED Instance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    hintText: '192.168.1.25',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an IP address';
                    }
                    final ipRegex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
                    if (!ipRegex.hasMatch(value)) {
                      return 'Please enter a valid IP address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name (optional)',
                    hintText: 'Living Room Lights',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEditing) ...[
                      TextButton(
                        onPressed: _isLoading ? null : () => _deleteInstance(apiService),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                      const Spacer(),
                    ],
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _submitForm(apiService, isEditing),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Add Instance'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm(ApiService apiService, bool isEditing) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await apiService.updateInstance(
          widget.instance!,
          _ipController.text.trim(),
          widget.instance!.name == _nameController.text.trim() ? '' : _nameController.text.trim(),
        );

      } else {
        await apiService.createInstance(
          _ipController.text.trim(),
          _nameController.text.trim(),
        );

        if (widget.onInstanceCreated != null)
          Future.delayed(Duration(milliseconds: 500), () => {
            widget.onInstanceCreated!(apiService.instances.length-1)
          });
      }
      if (mounted)
        Navigator.pop(context, true);
    } catch (e) {
      // Error is already handled by ApiService
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteInstance(ApiService apiService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Instance'),
        content: const Text('Are you sure you want to delete this instance? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await apiService.deleteInstance(widget.instance!.id);
      if (mounted) Navigator.pop(context, false);
    } catch (e) {
      // Error is already handled by ApiService
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
