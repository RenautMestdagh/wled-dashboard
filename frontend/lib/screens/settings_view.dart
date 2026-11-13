import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/scope.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late final _serverUrl = TextEditingController(text: context.settings.serverUrl);
  late final _apiKey = TextEditingController(text: context.settings.apiKey);
  bool _obscureKey = true;
  bool _connecting = false;

  @override
  void dispose() {
    _serverUrl.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    final s = S.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _connecting = true);
    try {
      await context.store.connect(_serverUrl.text.trim(), _apiKey.text.trim());
      if (mounted) showMessage(context, s.connected);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = context.settings;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(s.appearance, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: [
            ButtonSegment(value: ThemeMode.light, icon: const Icon(Icons.light_mode), label: Text(s.themeLight)),
            ButtonSegment(value: ThemeMode.system, icon: const Icon(Icons.brightness_auto), label: Text(s.themeSystem)),
            ButtonSegment(value: ThemeMode.dark, icon: const Icon(Icons.dark_mode), label: Text(s.themeDark)),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (selected) => settings.setThemeMode(selected.single),
        ),
        const SizedBox(height: 32),
        Text(s.connection, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!kIsWeb) ...[
                TextFormField(
                  controller: _serverUrl,
                  decoration: InputDecoration(
                    labelText: s.serverUrl,
                    hintText: 'https://leds.example.com',
                    prefixIcon: const Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (value) =>
                      Uri.tryParse(value?.trim() ?? '')?.hasAuthority ?? false ? null : s.serverUrlInvalid,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _apiKey,
                obscureText: _obscureKey,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: s.apiKey,
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    tooltip: _obscureKey ? s.showKey : s.hideKey,
                    icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? s.apiKeyRequired : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _connecting ? null : _connect,
                icon: _connecting
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(s.testAndSave),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
