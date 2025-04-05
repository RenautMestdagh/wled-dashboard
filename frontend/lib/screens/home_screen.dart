import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'instance_screen.dart';
import 'presets_screen.dart';
import 'settings_screen.dart';
import '../widgets/tab_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Check if any instance is powered on
  bool _isAnyInstanceOn(ApiService apiService) {
    // If we have no instances or instances with state, consider the master power "off"
    if (apiService.instances.isEmpty) {
      return false;
    }

    // Check if we have any powered on instances
    for (final instance in apiService.instances) {
      // Attempt to get the power state from our cached data
      final instanceState = apiService.getDeviceStateCached(instance.id);
      if (instanceState != null && instanceState['on'] == true) {
        return true;
      }
    }

    return false;
  }

  // Toggle power for all instances
  Future<void> _toggleAllPower(ApiService apiService) async {
    final bool turnOn = !_isAnyInstanceOn(apiService);

    // Show a loading indicator
    setState(() {}); // Trigger rebuild to show loading indicator

    try {
      // Create a list of futures for toggling each instance
      final futures = apiService.instances.map((instance) async {
        return apiService.updateDeviceState(instance.id, {'on': turnOn});
      }).toList();

      // Wait for all instances to be updated
      await Future.wait(futures);

      await apiService.refreshDeviceStates();

      // Show success message
      apiService.setSuccessMessage(turnOn ? 'All instances turned on' : 'All instances turned off');
    } catch (e) {
      // Show error message
      apiService.setErrorMessage('Failed to toggle power for all instances');
    }

    // Trigger a rebuild to update the UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        // Handle messages
        if (apiService.errorMessage != null || apiService.successMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (apiService.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(apiService.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (apiService.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(apiService.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            }
            // Clear messages after showing
            apiService.clearMessages();
          });
        }

        _screens = [
          PresetsScreen(presets: apiService.presets),
          ...apiService.instances.asMap().entries.map((entry) {
            final index = entry.key;
            return InstanceScreen(
              instance: entry.value,
              onInstanceDeleted: () => _handleInstanceDeleted(index),
            );
          }).toList(),
          const SettingsScreen(),
        ];

        // Determine the master power state
        final bool anyInstanceOn = _isAnyInstanceOn(apiService);

        return Scaffold(
          appBar: AppBar(
            title: const Text('WLED Controller'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            actions: [
              if (_currentIndex == 0)
                if (!apiService.isLoading)
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      // color: anyInstanceOn ? Colors.green : Colors.red,
                    ),
                    onPressed: () => apiService.fetchData(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

              // Master power button
              if (apiService.instances.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.power_settings_new,
                    color: anyInstanceOn ? Colors.green : Colors.red,
                  ),
                  onPressed: () => _toggleAllPower(apiService),
                ),
            ],
          ),
          body: apiService.isLoading && (apiService.instances.isEmpty && apiService.presets.isEmpty)
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading data...'),
                    ],
                  ),
                )
              : IndexedStack(
                  index: _currentIndex < _screens.length ? _currentIndex : 0,
                  children: _screens,
                ),
            bottomNavigationBar: TabNavigation(
              currentIndex: _currentIndex < _screens.length ? _currentIndex : 0,
              onTabSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            )
        );
      },
    );
  }

  void _handleInstanceDeleted(int deletedIndex) {
    setState(() {
      _currentIndex--;
    });
  }
}
