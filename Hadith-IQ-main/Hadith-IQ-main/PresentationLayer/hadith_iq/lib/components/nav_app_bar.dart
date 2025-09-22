import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hadith_iq/provider/server_status_provider.dart';
import 'package:provider/provider.dart';

class MyNavAppBar extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final List<Map<String, dynamic>> navItems; // List of navigation items
  // Default empty list for navItems if null list is passed
  static List<Map<String, dynamic>> defaultList = [
    {'title': 'Home', 'onPressed': () {}}
  ];
  const MyNavAppBar(
      {super.key, required this.onToggleTheme, required this.navItems});

  @override
  MyNavAppBarState createState() => MyNavAppBarState();
}

class MyNavAppBarState extends State<MyNavAppBar> {
  String selectedNavItem = ''; // Tracks the currently selected item
  bool isDarkMode = false; // Tracks theme mode
  double _indicatorOffset = 0.0; // Tracks the sliding indicator's position
  double _indicatorWidth = 0.0; // Tracks the sliding indicator's width
  final List<GlobalKey> _navKeys =
      []; // GlobalKeys for measuring positions of nav items

  @override
  void initState() {
    super.initState();
    final navItems =
        widget.navItems.isNotEmpty ? widget.navItems : MyNavAppBar.defaultList;
    selectedNavItem = navItems[0]['title']; // Set default selected item
    for (var _ in navItems) {
      _navKeys.add(GlobalKey());
    } // Initialize keys for each nav item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorProperties(); // Initialize the indicator position and width
    });
  }

  void _updateIndicatorProperties() {
    final selectedIndex =
        widget.navItems.indexWhere((item) => item['title'] == selectedNavItem);

    if (selectedIndex != -1) {
      final RenderBox? renderBox = _navKeys[selectedIndex]
          .currentContext
          ?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        final textWidth = _calculateTextWidth(selectedNavItem) + 20;

        setState(() {
          // Adjust the offset to center the indicator under the text
          _indicatorOffset =
              offset.dx + renderBox.size.width / 2 - textWidth / 2;
          _indicatorWidth = textWidth;
        });
      }
    }
  }

  double _calculateTextWidth(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateIndicatorProperties(); // Update the indicator position on window resize
        });

        return Container(
          color: Theme.of(context).colorScheme.surface, // Background color
          height: 160.0, // Define the height of the top bar
          child: Stack(
            children: [
              // Sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _indicatorOffset,
                top: 0, // Position it above the text
                child: Container(
                  height: 90.0,
                  width: _indicatorWidth, // Dynamic width of the indicator
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: _getBorderRadiusForSelectedItem(),
                  ),
                ),
              ),

              // Navbar items
              Positioned.fill(
                top: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Image.asset(
                        'assets/images/FYP_Logo.png',
                        height: 68.0,
                        width: 68.0,
                      ),
                    ),

                    // Navigation Items
                    Row(
                      children: List.generate(widget.navItems.length, (index) {
                        final item = widget.navItems[index];
                        return index < widget.navItems.length - 1
                            ? Row(
                                children: [
                                  _navItem(item['title'], index,
                                      item['onPressed'], item['isRoutable']),
                                  const SizedBox(width: 55),
                                ],
                              )
                            : _navItem(item['title'], index, item['onPressed'],
                                item['isRoutable']);
                      }),
                    ),

                    // Theme Toggle Button
                    Padding(
                      padding: const EdgeInsets.only(right: 47, top: 15),
                      child: Row(
                        children: [
                          // Server Status Circle
                          Consumer<ServerStatusProvider>(
                            builder: (context, statusProvider, _) {
                              final isOnline = statusProvider.isOnline;
                              final statusColor =
                                  isOnline ? Colors.green : Colors.grey;

                              return Tooltip(
                                message: isOnline
                                    ? "Server Online"
                                    : "Server Offline",
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontSize: 12,
                                ),
                                waitDuration: const Duration(milliseconds: 300),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 14),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),

                          Tooltip(
                            message: isDarkMode
                                ? "Light Mode"
                                : "Dark Mode", // Tooltip message
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                fontSize: 12),
                            waitDuration: const Duration(milliseconds: 300),
                            child: IconButton(
                              icon: Icon(
                                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                color: isDarkMode
                                    ? Colors.amber
                                    : Theme.of(context).colorScheme.secondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  isDarkMode = !isDarkMode; // Toggle theme mode
                                });
                                widget
                                    .onToggleTheme(); // Trigger theme change action
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem(
      String title, int index, VoidCallback onPressed, bool isRoutable) {
    final bool isSelected = selectedNavItem == title;

    return MouseRegion(
      cursor: SystemMouseCursors.click, // Change cursor to hand
      child: GestureDetector(
        onTap: () {
          if (isRoutable) {
            setState(() {
              selectedNavItem = title;
              _updateIndicatorProperties();
            });
          }
          onPressed(); // Execute the onPressed functionality passed from the parent
        },
        child: Column(
          key: _navKeys[index], // Assign unique key to each item
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Determine border radius based on the selected item
  BorderRadius _getBorderRadiusForSelectedItem() {
    final int lastIndex = widget.navItems.length - 1; // Index of the last item
    final index =
        widget.navItems.indexWhere((item) => item['title'] == selectedNavItem);

    if (index == 0) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(15.0),
        bottomRight: Radius.circular(40.0),
      );
    } else if (index == lastIndex) {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(40.0),
        bottomRight: Radius.circular(15.0),
      );
    } else {
      return const BorderRadius.only(
        bottomLeft: Radius.circular(35.0),
        bottomRight: Radius.circular(35.0),
      ); // All other items have circular bottom corners
    }
  }
}
