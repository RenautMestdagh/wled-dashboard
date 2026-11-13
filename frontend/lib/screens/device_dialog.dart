import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/scope.dart';

/// Adds a device, or changes the address and name of [instance]. Completes with true when saved.
Future<bool> showDeviceDialog(BuildContext context, [Instance? instance]) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _DeviceDialog(instance: instance),
    ) ??
    false;

final _ipv4 = RegExp(r'^((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)$');

class _DeviceDialog extends StatefulWidget {
  const _DeviceDialog({this.instance});

  final Instance? instance;

  @override
  State<_DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<_DeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _ip = TextEditingController(text: widget.instance?.ip);
  late final _name = TextEditingController(text: widget.instance?.name);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ip.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final s = S.of(context);
    final store = context.store;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final instance = widget.instance;
      if (instance == null) {
        await store.addInstance(_ip.text.trim(), _name.text.trim());
      } else {
        await store.updateInstance(instance.id, _ip.text.trim(), _name.text.trim());
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.error == ApiError.device ? s.noWledAtAddress : errorText(s, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(widget.instance == null ? s.addDevice : s.editDevice),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _ip,
              autofocus: widget.instance == null,
              decoration: InputDecoration(labelText: s.ipAddress, hintText: '192.168.1.25'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => _ipv4.hasMatch(value?.trim() ?? '') ? null : s.ipAddressInvalid,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: s.nameOptional, helperText: s.nameOptionalHelp, helperMaxLines: 2),
              textCapitalization: TextCapitalization.sentences,
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
        FilledButton(onPressed: _saving ? null : _save, child: Text(s.save)),
      ],
    );
  }
}
