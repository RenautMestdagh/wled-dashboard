import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/instance.dart';
import '../screens/settings_screen.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import 'instance_modal.dart';

class TabNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const TabNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<TabNavigation> createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  final ScrollController _tabBarScrollController = ScrollController();

  @override
  void dispose() {
    _tabBarScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Consumer<ApiService>(builder: (context, apiService, child) {
          final theme = Theme.of(context);
          final isDarkMode = theme.brightness == Brightness.dark;

          // Color definitions
          final bgColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
          final textColor = isDarkMode ? Colors.white : Colors.black;
          final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[400]!;
          final selectedTabColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

          return Container(
            height: 60,
            color: bgColor,
            child: Row(
              children: [
                // Scrollable Tabs Section
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Listener(
                            onPointerSignal: (pointerSignal) {
                              if (pointerSignal is PointerScrollEvent) {
                                _tabBarScrollController.jumpTo(
                                  (_tabBarScrollController.offset + pointerSignal.scrollDelta.dx * 3).clamp(0.0, _tabBarScrollController.position.maxScrollExtent),
                                );
                              }
                            },
                            child: GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                _tabBarScrollController.jumpTo(
                                  (_tabBarScrollController.offset - details.delta.dx).clamp(0.0, _tabBarScrollController.position.maxScrollExtent),
                                );
                              },
                              child: SingleChildScrollView(
                                controller: _tabBarScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: _buildTabRow(
                                    instances: apiService.instances,
                                    currentIndex: widget.currentIndex,
                                    textColor: textColor,
                                    selectedTabColor: selectedTabColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Gradient Overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      bgColor.withAlpha(0),
                                      bgColor.withAlpha(255),
                                      bgColor.withAlpha(255),
                                      bgColor.withAlpha(0),
                                    ],
                                    stops: const [0.0, 0.01, 0.99, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstOut,
                                child: Container(color: bgColor),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Settings Icon
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.settings, color: textColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10)
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildTabRow({
    required List<WLEDInstance> instances,
    required int currentIndex,
    required Color textColor,
    required Color selectedTabColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // General Tab
        _buildTabItem(
          0,
          'Algemeen',
          currentIndex,
          textColor,
          selectedTabColor,
        ),
        // Instance Tabs (wrapped in ListenableBuilder)
        ...instances.asMap().entries.map((entry) {
          final index = entry.key;
          final instance = entry.value;
          final tabIndex = index + 1;

          return ListenableBuilder(
            listenable: instance,
            builder: (context, _) {
              return _buildTabItem(
                tabIndex,
                instance.name == '' ? 'WLED' : instance.name,
                currentIndex,
                textColor,
                selectedTabColor,
              );
            },
          );
        }),
        // Add (+) Tab
        _buildTabItem(
          -1,
          '+',
          currentIndex,
          textColor,
          selectedTabColor,
        ),
      ],
    );
  }

  Widget _buildTabItem(
    int index,
    String text,
    int currentIndex,
    Color textColor,
    Color selectedTabColor,
  ) {
    final isSelected = index == currentIndex;
    final isGeneralTab = index == 0;

    return GestureDetector(
      onTap: () {
        if (index >= 0) {
          widget.onTabSelected(index);
        } else {
          showDialog(
            context: context,
            builder: (context) => InstanceModal(
              onInstanceCreated: (newIndex) {
                widget.onTabSelected(newIndex + 1);
              },
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedTabColor
              : isGeneralTab
                  ? selectedTabColor.withAlpha(77) // Slightly visible when not selected
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: isGeneralTab && !isSelected ? Border.all(color: selectedTabColor.withAlpha(127), width: 1) : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: isSelected || isGeneralTab ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
