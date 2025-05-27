import 'package:flutter/material.dart';
import 'package:frontend/screens/reorder_screen.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;
  late final FocusNode _urlFocusNode;
  late final FocusNode _keyFocusNode;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    _urlController = TextEditingController(text: apiService.baseUrl);
    _keyController = TextEditingController(text: apiService.apiKey);
    _urlFocusNode = FocusNode();
    _keyFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _urlFocusNode.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ApiService>(
        builder: (context, apiService, child) {

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (apiService.isLoading)
                  const LinearProgressIndicator(),
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 5,
                  child: Consumer<ThemeService>(
                    builder: (context, themeService, child) {
                      return SwitchListTile(
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.toggleTheme(value);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Reorder',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 5,
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        title: Text(
                          'Instances',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        trailing: const Icon(Icons.swap_vert),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReorderScreen(
                                isInstances: true,
                                items: apiService.instances,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        title: Text(
                          'Presets',
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        trailing: const Icon(Icons.swap_vert),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReorderScreen(
                                isInstances: false,
                                items: apiService.presets,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'API Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _urlController,
                          focusNode: _urlFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'API Base URL',
                            hintText: 'https://wledserver.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _keyController,
                          focusNode: _keyFocusNode,
                          decoration: InputDecoration(
                            labelText: 'API Key',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.key),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureApiKey = !_obscureApiKey;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscureApiKey,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: apiService.isLoading
                                ? null
                                : () async {
                              // Clear focus from text fields
                              _urlFocusNode.unfocus();
                              _keyFocusNode.unfocus();

                              // Clear any existing messages
                              apiService.clearMessages();

                              try {
                                await apiService.updateSettings(
                                  _urlController.text,
                                  _keyController.text,
                                );
                              } catch (e) {
                                // Errors are already handled in updateSettings
                              }
                            },
                            child: apiService.isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Text('Save Settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}