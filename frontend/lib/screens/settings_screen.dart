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
  bool _isDiscovering = false;
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

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(51),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          if (!isFirst) Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(12) : Radius.zero,
              bottom: isLast ? const Radius.circular(12) : Radius.zero,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(icon, size: 24),
              title: Text(title),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: trailing,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Consumer<ApiService>(
        builder: (context, apiService, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Appearance
                _buildSettingsGroup(
                  title: 'APPEARANCE',
                  children: [
                    Consumer<ThemeService>(
                      builder: (context, themeService, child) {
                        return _buildListTile(
                          title: 'Dark Mode',
                          icon: themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          trailing: Switch(
                            value: themeService.isDarkMode,
                            onChanged: (value) {
                              themeService.toggleTheme(value);
                            },
                          ),
                          isFirst: true,
                          isLast: true,
                        );
                      },
                    ),
                  ],
                ),

                // API Connection
                _buildSettingsGroup(
                  title: 'API CONNECTION',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: apiService.isLoading || _isDiscovering
                                  ? null
                                  : () async {
                                _urlFocusNode.unfocus();
                                _keyFocusNode.unfocus();
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
                              child: apiService.isLoading && !_isDiscovering
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text('Test & Save Connection'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Tools (only show when API is healthy)
                if (apiService.isHealthy)
                  _buildSettingsGroup(
                    title: 'TOOLS',
                    children: [
                      _buildListTile(
                        title: 'Autodiscover',
                        subtitle: _isDiscovering ? 'Searching for instances...' : 'Find available instances',
                        icon: Icons.radar,
                        trailing: _isDiscovering
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.chevron_right),
                        onTap: _isDiscovering
                            ? null
                            : () async {
                          _urlFocusNode.unfocus();
                          _keyFocusNode.unfocus();
                          setState(() {
                            _isDiscovering = true;
                          });

                          apiService.clearMessages();

                          try {
                            final bool newInstances = await apiService.autodiscoverInstances();
                            if (newInstances) {
                              await apiService.fetchData();
                            }
                          } catch (e) {
                            // Errors are already handled in updateSettings
                          } finally {
                            setState(() {
                              _isDiscovering = false;
                            });
                          }
                        },
                        isFirst: true,
                      ),
                      _buildListTile(
                        title: 'Reorder Instances',
                        subtitle: 'Change the order of instances',
                        icon: Icons.reorder,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _urlFocusNode.unfocus();
                          _keyFocusNode.unfocus();
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
                      _buildListTile(
                        title: 'Reorder Presets',
                        subtitle: 'Change the order of presets',
                        icon: Icons.palette,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _urlFocusNode.unfocus();
                          _keyFocusNode.unfocus();
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
                        isLast: true,
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}