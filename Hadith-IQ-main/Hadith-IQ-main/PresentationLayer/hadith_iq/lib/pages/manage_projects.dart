// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hadith_iq/api/project_api.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:hadith_iq/components/popup_dialogs.dart';
import 'package:hadith_iq/components/search_bar.dart';
import 'package:hadith_iq/provider/manage_projects_provider.dart';
import 'package:hadith_iq/provider/server_status_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

class ManageProjectsPage extends StatefulWidget {
  final Function(String) importHadithFile;

  const ManageProjectsPage({
    super.key,
    required this.importHadithFile,
  });

  @override
  State<ManageProjectsPage> createState() => ManageProjectsPageState();
}

class ManageProjectsPageState extends State<ManageProjectsPage> {
  ProjectService projectService = ProjectService();
  // controller for TextField
  TextEditingController searchController = TextEditingController();
  // bool showText = true;
  List searchProjects = [];
  bool showWelcomeContent = true;
  bool isGridView = false;
  double searchBarBottomOffset = 0.0; // Initial offset below search bar
  final GlobalKey _searchBarKey = GlobalKey();

  List<List<String>> _localProjects = [];
  List<List<String>> filteredProjects = [];
  final GlobalKey importButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    filteredProjects = _localProjects;
  }

  // Refresh projects list
  void _refreshProjects() async {
    final fetchedProjects = await projectService.fetchProjects();
    setState(() {
      _localProjects = fetchedProjects;
    });
  }

  // Method to show the Add Project dialog
  Future<void> showAddProjectDialog(
    BuildContext context,
  ) async {
    final TextEditingController projectController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return LayoutBuilder(builder: (layoutContext, constraints) {
          final mediaSize = MediaQuery.of(layoutContext).size;

          // Close the dialog dynamically if screen shrinks
          if (mediaSize.height < 650 || mediaSize.width < 1200) {
            Future.microtask(() {
              if (Navigator.canPop(dialogContext)) {
                Navigator.of(dialogContext).pop();
              }
            });
          }
          return Center(
            child: AlertDialog(
              backgroundColor: Theme.of(layoutContext).colorScheme.surface,
              title: const Center(
                child: Text(
                  "Add New Project",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              content: TextField(
                controller: projectController,
                decoration: const InputDecoration(
                  label: Text("Project Name"),
                  border: OutlineInputBorder(),
                  hintStyle: TextStyle(
                    fontSize: 14,
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(25),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(layoutContext).colorScheme.onPrimary,
                    foregroundColor:
                        Theme.of(layoutContext).colorScheme.primary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(layoutContext).colorScheme.primary,
                        width: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    fixedSize: const Size(110, 35),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final projectName = projectController.text.trim();
                    if (projectName.isNotEmpty) {
                      final response =
                          await projectService.addProject(projectName);
                      if (response['status']) {
                        final currentDate = _getCurrentDate();
                        setState(() {
                          _localProjects
                              .add([projectName, currentDate, currentDate]);
                        });
                        SnackBarCollection().successSnackBar(
                            layoutContext,
                            response['message'],
                            Icon(Iconsax.tick_square,
                                color: Theme.of(layoutContext)
                                    .colorScheme
                                    .onTertiary),
                            true);
                        _refreshProjects();
                      } else {
                        SnackBarCollection().errorSnackBar(
                            dialogContext,
                            "Failed to add project!",
                            Icon(Iconsax.danger5,
                                color: Theme.of(layoutContext)
                                    .colorScheme
                                    .onError),
                            true);
                      }
                    }
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(layoutContext).colorScheme.primary,
                    foregroundColor:
                        Theme.of(layoutContext).colorScheme.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: Theme.of(layoutContext).colorScheme.onPrimary,
                        width: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    fixedSize: const Size(110, 35),
                  ),
                  child: const Text(
                    "Add",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showPopover() {
    // Use the button's context (via its GlobalKey) to anchor the popover
    final BuildContext buttonContext = importButtonKey.currentContext!;
    showPopover(
      context: buttonContext,
      bodyBuilder: (context) => ImportDropdownMenuItems(
        hadithsButtonPressed: () {
          widget.importHadithFile("hadith");
          Navigator.pop(context);
        },
        narratorsButtonPressed: () {
          widget.importHadithFile("narrator");
          Navigator.pop(context);
        },
      ),
      height: 80,
      width: 135,
      backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
      direction: PopoverDirection.right,
      barrierColor: Colors.transparent,
      radius: 12,
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
  }

  void updateSearch(String query) {
    // setState(() {
    //   filteredProjects = _localProjects
    //       .where((item) => item.toLowerCase().contains(query.toLowerCase()))
    //       .toList(); // Filter items based on the search query
    // });
  }

  String? selectedFilePath;

  void handleListIconPress() {
    setState(() {
      if (isGridView) {
        showWelcomeContent = true;
        isGridView = false;
      } else {
        showWelcomeContent = false;
      }
    });
  }

  void toggleContentVisibility() {
    setState(() {
      showWelcomeContent = !showWelcomeContent;
    });
  }

  void _getSearchBarPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox =
          _searchBarKey.currentContext!.findRenderObject() as RenderBox;
      final Offset position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        if (!showWelcomeContent) {
          searchBarBottomOffset = position.dy + 50; // Set the bottom offset
          isGridView = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final manageProjects = Provider.of<ManageProjectsProvider>(context);
    return Stack(
      children: [
        // logo in background
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomRight,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topLeft, // Display the top-left portion
                widthFactor:
                    0.65, // Adjust to show a portion horizontally (percentage)
                heightFactor:
                    0.73, // Adjust to show a portion vertically (percentage)
                child: Opacity(
                  opacity: 0.07, // Adjust opacity
                  child: Image.asset(
                    'assets/images/FYP_Logo.png',
                    fit: BoxFit.cover,
                    width: 1000, // Original image width
                    height: 650, // Original image height
                  ),
                ),
              ),
            ),
          ),
        ),
        // Animated Text
        AnimatedPositioned(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          top: showWelcomeContent
              ? MediaQuery.of(context).size.height > 900
                  ? MediaQuery.of(context).size.height * 0.25
                  : MediaQuery.of(context).size.height * 0.07
              : -250, // Slide up or hide the content
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 35),
                Container(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
                    style: GoogleFonts.reemKufi(
                      fontSize: 62.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Search Bar
        AnimatedPositioned(
          key: _searchBarKey,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          top: showWelcomeContent
              ? MediaQuery.of(context).size.height > 900
                  ? MediaQuery.of(context).size.height * 0.4
                  : MediaQuery.of(context).size.height * 0.23
              : 0, // Slide up or hide the content
          left: 0,
          right: 0,
          onEnd:
              _getSearchBarPosition, // Trigger position update after animation
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Search Bar
                MySearchBar(
                  hintText: 'Search Project',
                  searchController: searchController,
                  onTap: () {},
                  onSubmitted: updateSearch,
                  isWithLastIcon: true,
                  onLastIconPressed: handleListIconPress,
                  tooltipText: "All Projects",
                ),
              ],
            ),
          ),
        ),
        if (isGridView)
          Positioned(
            top: searchBarBottomOffset, // Dynamically set the position
            left: 100,
            right: 100,
            bottom: 70,
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height - searchBarBottomOffset,
              width: MediaQuery.of(context).size.width * 0.8,
              child: FutureBuilder(
                  key: ValueKey(_localProjects),
                  future: projectService.fetchProjects(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.cloud_cross,
                            color: Theme.of(context).colorScheme.error,
                            size: 60.0,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Server connection error!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dnd_forwardslash_outlined,
                            color: Theme.of(context).colorScheme.error,
                            size: 60.0,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'No projects available!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ));
                    } else {
                      _localProjects = snapshot.data!;
                      return Padding(
                          padding: const EdgeInsets.only(
                              left: 70, right: 70, bottom: 20),
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 30.0,
                              mainAxisSpacing: 30.0,
                              mainAxisExtent: 70.0,
                            ),
                            itemCount: _localProjects.length,
                            itemBuilder: (context, index) {
                              var projectName = _localProjects[index][0];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: InkWell(
                                    onTap: () {
                                      manageProjects.selectProject(projectName);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onDoubleTap: () => PopupDialogs()
                                                  .renameItemPopupDialog(
                                                context,
                                                index,
                                                _localProjects[index][0],
                                                (renameController) async {
                                                  final newName =
                                                      renameController.text
                                                          .trim();
                                                  final oldName =
                                                      _localProjects[index][0];

                                                  if (newName.isNotEmpty) {
                                                    final response =
                                                        await projectService
                                                            .renameProject(
                                                                oldName,
                                                                newName);
                                                    if (response['status']) {
                                                      setState(() {
                                                        _localProjects[index]
                                                            [0] = newName;
                                                      });
                                                      SnackBarCollection().successSnackBar(
                                                          context,
                                                          response['message'],
                                                          Icon(
                                                              Iconsax
                                                                  .tick_square,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onTertiary),
                                                          true);
                                                      _refreshProjects();
                                                    } else {
                                                      SnackBarCollection().errorSnackBar(
                                                          context,
                                                          "Failed to rename project!",
                                                          Icon(Iconsax.danger5,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onError),
                                                          true);
                                                    }
                                                  }
                                                },
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10),
                                                    child: Text(
                                                      projectName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10,
                                                            bottom: 3),
                                                    child: Text(
                                                      _localProjects[index][1],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Delete button
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 7, bottom: 7),
                                              child: IconButton(
                                                icon: Icon(Icons.delete_rounded,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                                onPressed: () => PopupDialogs()
                                                    .deleteItemPopupDialog(
                                                        context,
                                                        index,
                                                        _localProjects[index]
                                                            [0],
                                                        "Project", () async {
                                                  final response =
                                                      await projectService
                                                          .deleteProject(
                                                              _localProjects[
                                                                  index][0]);
                                                  if (response['status']) {
                                                    setState(() {
                                                      _localProjects
                                                          .removeAt(index);
                                                    });
                                                    SnackBarCollection()
                                                        .successSnackBar(
                                                            context,
                                                            response['message'],
                                                            Icon(
                                                                Iconsax
                                                                    .tick_square,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onTertiary),
                                                            true);
                                                    _refreshProjects();
                                                  } else {
                                                    SnackBarCollection()
                                                        .errorSnackBar(
                                                            context,
                                                            "Failed to delete project!",
                                                            Icon(
                                                                Iconsax.danger5,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onError),
                                                            true);
                                                  }
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ));
                    }
                  }),
            ),
          ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(left: 30.0, bottom: 30.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 10,
                children: [
                  Consumer<ServerStatusProvider>(
                    builder: (context, serverStatus, _) {
                      final isServerOnline = serverStatus.isOnline;

                      return ElevatedButton(
                        key: importButtonKey,
                        onPressed: isServerOnline ? () => _showPopover() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          elevation: 7,
                          fixedSize: const Size(50, 55),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.onSecondary,
                              width: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.note_add_outlined,
                            size: 28,
                            color: isServerOnline
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSecondary
                                    .withValues(
                                      alpha: 0.4,
                                    ),
                          ),
                        ),
                      );
                    },
                  ),
                  Consumer<ServerStatusProvider>(
                    builder: (context, serverStatus, _) {
                      final isServerOnline = serverStatus.isOnline;

                      return ElevatedButton(
                        onPressed: isServerOnline
                            ? () {
                                showAddProjectDialog(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          elevation: 7,
                          fixedSize: const Size(50, 55),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.onPrimary,
                              width: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 28,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(
                                  alpha: isServerOnline ? 1.0 : 0.4,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(right: 20, bottom: 20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Tooltip(
                  message: "About",
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 12),
                  waitDuration: const Duration(milliseconds: 300),
                  child: IconButton.outlined(
                    onPressed: () => PopupDialogs().showAboutDialog(context),
                    icon: Icon(
                      Icons.question_mark_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 20, minHeight: 20),
                    style: ButtonStyle(
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        ),
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )),
            ),
          ),
        ),
      ],
    );
  }
}

class ImportDropdownMenuItems extends StatelessWidget {
  final VoidCallback hadithsButtonPressed;
  final VoidCallback narratorsButtonPressed;
  const ImportDropdownMenuItems(
      {super.key,
      required this.hadithsButtonPressed,
      required this.narratorsButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                  onPressed: hadithsButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    //Theme.of(context).colorScheme.surfaceContainerHigh,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
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
                          Icons.menu_book_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            "Hadiths",
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
              width: 120,
              child: ElevatedButton(
                  onPressed: narratorsButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    //Theme.of(context).colorScheme.surfaceContainerHigh,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
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
                          Iconsax.profile_2user,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            "Narrators",
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
