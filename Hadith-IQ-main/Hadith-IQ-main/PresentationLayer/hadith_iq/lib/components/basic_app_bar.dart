import 'package:flutter/material.dart';
import 'package:hadith_iq/components/popup_dialogs.dart';
import 'package:hadith_iq/provider/server_status_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

class MyBasicAppBar extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String projectName;
  final VoidCallback projectButtonOnPressed;

  const MyBasicAppBar(
      {super.key,
      required this.onToggleTheme,
      required this.projectName,
      required this.projectButtonOnPressed});

  @override
  MyNavAppBarState createState() => MyNavAppBarState();
}

class MyNavAppBarState extends State<MyBasicAppBar> {
  bool isDarkMode = false; // Tracks theme mode
  final GlobalKey projectButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void _showPopover() {
    // Use the button's context (via its GlobalKey) to anchor the popover
    final BuildContext buttonContext = projectButtonKey.currentContext!;
    showPopover(
      context: buttonContext, // Use the button's context
      bodyBuilder: (context) => ProjectDropdownMenuItems(
        projectButtonOnPressed: () {
          Navigator.pop(context); // Close the popover first
          widget.projectButtonOnPressed(); // Then execute the button action
        },
      ),
      height: 95,
      width: 125,
      backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
      direction: PopoverDirection.bottom, // Adjust popover direction as needed
      barrierColor: Colors.transparent, // Optional: make barrier transparent
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      // decoration: BoxDecoration(
      //     color: Theme.of(context).colorScheme.surface,
      //     boxShadow: [
      //       BoxShadow(
      //         color: Theme.of(context).colorScheme.secondary.withOpacity(0.35),
      //         offset: const Offset(-10, 5),
      //         blurRadius: 7,
      //         spreadRadius: 2,
      //       ),
      //       BoxShadow(
      //           color: Theme.of(context).colorScheme.surface,
      //           offset: const Offset(-20, 0)),
      //     ]),
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Center(
                    child: Tooltip(
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
                          color: Theme.of(context).colorScheme.onSecondary,
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
                          widget.onToggleTheme(); // Trigger theme change action
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(right: 50),
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
                      Container(
                        width: 200,
                        height: 27,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: const BorderRadius.all(Radius.circular(25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                widget.projectName.length >= 20
                                    ? "${widget.projectName.substring(0, 20)}..."
                                    : widget.projectName,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSecondary,
                                    fontSize: 13),
                              ),
                            ),
                            IconButton(
                              key: projectButtonKey,
                              onPressed: () {
                                _showPopover();
                              },
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Theme.of(context).colorScheme.onSecondary,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectDropdownMenuItems extends StatelessWidget {
  final VoidCallback projectButtonOnPressed;
  const ProjectDropdownMenuItems(
      {super.key, required this.projectButtonOnPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            SizedBox(
              width: 110,
              child: ElevatedButton(
                  onPressed: projectButtonOnPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    //Theme.of(context).colorScheme.surfaceContainerHigh,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Icon(
                          Iconsax.layer,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            "Projects",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ])),
            ),
            const SizedBox(
              height: 5,
            ),
            SizedBox(
              width: 110,
              child: ElevatedButton(
                  onPressed: () => PopupDialogs().showAboutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    //Theme.of(context).colorScheme.surfaceContainerHigh,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Icon(
                          Icons.question_mark_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            "About",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ])),
            ),
          ],
        ));
  }
}
