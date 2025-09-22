// ignore_for_file: use_build_context_synchronously

import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:hadith_iq/api/book_api.dart';
import 'package:hadith_iq/api/hadith_api.dart';
import 'package:hadith_iq/components/nav_app_bar.dart';

import 'package:hadith_iq/components/my_drawer.dart';
import 'package:hadith_iq/components/hover_icon_button.dart';
import 'package:hadith_iq/components/my_tooltip.dart';
import 'package:hadith_iq/components/popup_dialogs.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:hadith_iq/pages/all_hadith_page.dart';
import 'package:hadith_iq/pages/all_narrator_page.dart';
import 'package:hadith_iq/pages/dashboard.dart';
import 'package:hadith_iq/pages/manage_projects.dart';
import 'package:hadith_iq/pages/hadith_narrator_details.dart';
import 'package:hadith_iq/pages/narrators_page.dart';

import 'package:hadith_iq/pages/semantic_search.dart';
import 'package:hadith_iq/provider/hadith_details_notifier.dart';
import 'package:hadith_iq/provider/manage_projects_provider.dart';
import 'package:hadith_iq/provider/narrator_item_provider.dart';
import 'package:hadith_iq/util/pdf_generator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../util/import_file.dart';

class DesktopScaffold extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const DesktopScaffold({super.key, required this.onToggleTheme});

  @override
  State<DesktopScaffold> createState() => DesktopScaffoldState();
}

class DesktopScaffoldState extends State<DesktopScaffold> {
  final GlobalKey<SemanticSearchPageState> _semanticSearchKey = GlobalKey();
  final GlobalKey<NarratorsPageState> _narratorPageKey = GlobalKey();
  int manageProjectPageIndex = 0;
  int dashboardPageIndex = 1;
  int semanticSearchPageIndex = 2;
  int narratorsPageIndex = 3;
  int narratorDetailsPageIndex = 4;
  int allHadithPageIndex = 5;
  int allNarratorPageIndex = 6;
  int _prevSelectedIndex = 0;
  int _selectedIndex = 0;
  final HadithService _hadithService = HadithService();
  final BookService _bookService = BookService();
  bool isTopNavBarScreens = true;
  List<bool> appDrawerButtonPress = List.generate(
      3, (index) => false); // for by default state(selected) of drawer button
  String? selectedFilePath;
  Future<String?>? _importFuture;
  bool importingFile = false; // to show loading when importing file
  String currentProjectName = "";
  String narratorDetailsName = "";
  List<List<String>> narratedHadiths = [];
  String selectedHadith = '';
  String hadithDetails = '';
  String narratorDetails = '';
  bool isHadithDetails = false;
  List<String> sanad = [];
  List<List<String>> narratorTeachersStudents = [];

  ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Listen to changes in NarratorNotifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final narratorNotifier =
          Provider.of<NarratorProvider>(context, listen: false);
      narratorNotifier.addListener(_handleNarratorChange);
    });
    // Listen to changes in ProjectNotifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectNotifier =
          Provider.of<ManageProjectsProvider>(context, listen: false);
      projectNotifier.addListener(_handleGridItemClick);
    });
    // Listen to changes in HadithNotifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hadithNotifier =
          Provider.of<HadithDetailsProvider>(context, listen: false);
      hadithNotifier.addListener(_handleHadithDetails);
    });
  }

  NarratorProvider? narratorProvider;
  ManageProjectsProvider? projectsProvider;
  HadithDetailsProvider? hadithDetailsProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    narratorProvider = Provider.of<NarratorProvider>(context, listen: false);
    projectsProvider =
        Provider.of<ManageProjectsProvider>(context, listen: false);
    hadithDetailsProvider =
        Provider.of<HadithDetailsProvider>(context, listen: false);
  }

  @override
  void dispose() {
    narratorProvider?.removeListener(_handleNarratorChange);
    projectsProvider?.removeListener(_handleGridItemClick);
    hadithDetailsProvider?.removeListener(_handleHadithDetails);
    super.dispose();
  }

  Future<List<List<String>>> getSemanticallySearchedHadiths() async {
    final state = _semanticSearchKey.currentState;
    if (state != null) {
      return await state.getSemanticallySearchedHadiths();
    } else {
      return [];
    }
  }

  Future<List<String>> getFilenameAndPathToExport() async {
    return await _semanticSearchKey.currentState
            ?.getFilenameAndPathToExport() ??
        [];
  }

  Future<String?> _importFile(String type) async {
    importingFile = true;
    if (type == "narrator") {
      return await ImportFile.selectHtmlFile();
    } else if (type == "hadith") {
      return await ImportFile.selectCsvFile();
    }
    return null;
  }

  Future<List<String>> _handleGetAllBooks() async {
    try {
      var response = await _bookService.getAllBooks();
      return response;
    } on Exception catch (e) {
      SnackBarCollection().errorSnackBar(
          context,
          'Error fetching all books: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
    }
    return [];
  }

  Future<List<String>> _handleGetAllProjectBooks(String projectName) async {
    try {
      var response = await _bookService.getAllBooksOfProject(projectName);
      return response;
    } on Exception catch (e) {
      SnackBarCollection().errorSnackBar(
          context,
          'Error fetching all project books: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
    }
    return [];
  }

  // Function to handle the Global Import button press
  Future<String?> _handleGlobalImportButtonPress(String type) async {
    try {
      selectedFilePath = await _importFile(type);
      if (selectedFilePath == null) {
        SnackBarCollection().errorSnackBar(
            context,
            'No file selected.',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            true);
        return null;
      }
      var response = {};
      if (type == "hadith") {
        response = await _hadithService.importHadithCSV(selectedFilePath!);
        if (response['status']) {
          SnackBarCollection().successSnackBar(
              context,
              response['message'],
              Icon(Iconsax.tick_square,
                  color: Theme.of(context).colorScheme.onTertiary),
              true);
        } else {
          SnackBarCollection().errorSnackBar(
              context,
              'Failed to import File!',
              Icon(Iconsax.danger5,
                  color: Theme.of(context).colorScheme.onError),
              true);
        }
      } else if (type == "narrator") {
        PopupDialogs().showImportNarratorDetailsPopupDialog(
            context, "queryName", selectedFilePath!);
      }

      if (response['status'] == 'error') {
        SnackBarCollection().errorSnackBar(
            context,
            'Error occurred: ${response['message']}',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            true);
      } else {
        return selectedFilePath;
      }
    } catch (e) {
      SnackBarCollection().errorSnackBar(
          context,
          'Error importing file: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
    }
    return null;
  }

  // Function to handle the Import book button press
  Future<bool> _handleImportBookButtonPress(
      String projectName, List<String> books) async {
    try {
      var response =
          await _hadithService.importBookInProject(projectName, books);
      if (response['status']) {
        SnackBarCollection().successSnackBar(
            context,
            response['message'],
            Icon(Iconsax.tick_square,
                color: Theme.of(context).colorScheme.onTertiary),
            true);
        return true;
      } else {
        SnackBarCollection().errorSnackBar(
            context,
            'Failed to import book in project.',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            true);
      }
    } catch (e) {
      SnackBarCollection().errorSnackBar(
          context,
          'Error importing file: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
    }
    return false;
  }

  void _changePage(int toIndex) {
    setState(() {
      selectedIndexNotifier.value = toIndex;
      _prevSelectedIndex = _selectedIndex;
      _selectedIndex = toIndex;
      appDrawerButtonPress.fillRange(0, 3, false);
      if (_selectedIndex != manageProjectPageIndex &&
          _selectedIndex < allHadithPageIndex) {
        isTopNavBarScreens = false;
        if (_selectedIndex == dashboardPageIndex) {
          appDrawerButtonPress[0] = true;
        } else if (_selectedIndex == semanticSearchPageIndex) {
          appDrawerButtonPress[1] = true;
        } else if (_selectedIndex == narratorsPageIndex) {
          appDrawerButtonPress[2] = true;
        }
        if (_selectedIndex == narratorDetailsPageIndex) {
          if (_prevSelectedIndex == 1) {
            appDrawerButtonPress[1] = true;
          } else if (_prevSelectedIndex == 3) {
            appDrawerButtonPress[2] = true;
          }
        }
      } else {
        isTopNavBarScreens = true;
      }
    });
  }

  void _handleNarratorChange() {
    final narratorNotifier =
        Provider.of<NarratorProvider>(context, listen: false);
    setState(() {
      narratorDetailsName = narratorNotifier.selectedNarrator;
      narratedHadiths = narratorNotifier.narratedHadiths;
      narratorDetails = narratorNotifier.narratorDetails;
      sanad = [];
      isHadithDetails = false;
      narratorTeachersStudents = [
        narratorNotifier.narratorTeachers,
        narratorNotifier.narratorStudents
      ];
    });
    _changePage(narratorDetailsPageIndex);
  }

  void _handleHadithDetails() {
    final hadithNotifier =
        Provider.of<HadithDetailsProvider>(context, listen: false);
    setState(() {
      selectedHadith = hadithNotifier.selectedHadith;
      sanad = hadithNotifier.sanad;
      hadithDetails = hadithNotifier.books;
      isHadithDetails = true;
    });
    _changePage(narratorDetailsPageIndex);
  }

  void _handleGridItemClick() {
    final projectNotifier =
        Provider.of<ManageProjectsProvider>(context, listen: false);
    setState(() {
      currentProjectName = projectNotifier.selectedProject;
    });
    _changePage(dashboardPageIndex);
  }

  // Function to handle the AppBar project button press
  void _handleProjectButtonPress() {
    currentProjectName = "";
    _changePage(manageProjectPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isTopNavBarScreens
          ? PreferredSize(
              preferredSize: const Size.fromHeight(90.0),
              child: MyNavAppBar(
                onToggleTheme: widget.onToggleTheme,
                navItems: [
                  {
                    'title': 'Projects',
                    'onPressed': () => _handleProjectButtonPress(),
                    'isRoutable': true
                  },
                  {
                    'title': 'Hadiths',
                    'onPressed': () => _changePage(allHadithPageIndex),
                    'isRoutable': true
                  },
                  {
                    'title': 'Narrators',
                    'onPressed': () => _changePage(allNarratorPageIndex),
                    'isRoutable': true
                  },
                ],
              ),
            )
          : null,
      body: FutureBuilder<String?>(
          future: _importFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                if (importingFile) {
                  SnackBarCollection().errorSnackBar(
                      context,
                      snapshot.error.toString(),
                      Icon(Iconsax.danger5,
                          color: Theme.of(context).colorScheme.onError),
                      false);
                  importingFile = false;
                }
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                if (importingFile) {
                  SnackBarCollection().successSnackBar(
                      context,
                      'File imported: ${snapshot.data}',
                      Icon(Iconsax.tick_square,
                          color: Theme.of(context).colorScheme.onTertiary),
                      true);
                }
                importingFile = false;
              }
            }
            return Row(
              children: [
                if (!isTopNavBarScreens)
                  MyDrawer(
                    iconButtons: [
                      AnimatedHoverIconButton(
                        defaultIcon: Iconsax.chart_25,
                        hoverIcon: Iconsax.chart_215,
                        onPressed: () {
                          _changePage(dashboardPageIndex);
                        },
                        isSelected: appDrawerButtonPress[0],
                        defaultColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        hoverColor: Theme.of(context).colorScheme.primary,
                        size: 25,
                        tooltipText: "Dashboard",
                      ),
                      AnimatedHoverIconButton(
                        defaultIcon: Icons.menu_book_rounded,
                        hoverIcon: Icons.menu_book_rounded,
                        onPressed: () {
                          _changePage(semanticSearchPageIndex);
                        },
                        isSelected: appDrawerButtonPress[1],
                        defaultColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        hoverColor: Theme.of(context).colorScheme.primary,
                        size: 29,
                        tooltipText: "Hadiths",
                      ),
                      AnimatedHoverIconButton(
                        defaultIcon: Iconsax.profile_2user,
                        hoverIcon: Iconsax.profile_2user5,
                        onPressed: () {
                          _changePage(narratorsPageIndex);
                        },
                        isSelected: appDrawerButtonPress[2],
                        defaultColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        hoverColor: Theme.of(context).colorScheme.primary,
                        size: 25,
                        tooltipText: "Narrators",
                      ),
                    ],
                    bottomButtons: [
                      MyTooltip(
                        tooltipText: 'Export',
                        distance: 15,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_selectedIndex == semanticSearchPageIndex) {
                              // Await the result of getSemanticallySearchedHadiths()
                              List<List<String>> completeList =
                                  await getSemanticallySearchedHadiths();
                              List<String> resultList = completeList.isNotEmpty
                                  ? completeList[0]
                                  : [];
                              // List<String> sanads = completeList.isNotEmpty
                              //     ? completeList[1]
                              //     : [];

                              if (resultList.isEmpty) {
                                SnackBarCollection().errorSnackBar(
                                    context,
                                    "Export is only available for search results. No data found to export.",
                                    Icon(Iconsax.danger5,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onError),
                                    true);
                                return;
                              }
                              String query = resultList[0];
                              List<String> hadiths = resultList.sublist(1);
                              List<String> filenameAndPath =
                                  await getFilenameAndPathToExport(); // Filename: [0], Filepath: [1]
                              if (filenameAndPath[0] != "" &&
                                  filenameAndPath[1] != "") {
                                try {
                                  final pdfPath = await generateHadithPDF(
                                    query: query,
                                    hadiths: hadiths,
                                    sanads: [],
                                    title: 'مجموعة الأحاديث الشريفة',
                                    appName: 'HadithIQ',
                                    credits:
                                        'Developed by HadithIQ Team:\n• Syed Ali Masood\n• Malaika Tariq\nSpecial thanks to our supervisor Dr. Affan Rauf',
                                    logoPath: 'assets/images/FYP_Logo.png',
                                    fileName: filenameAndPath[0],
                                    savingDirectoryPath: filenameAndPath[1],
                                  );
                                  SnackBarCollection().successSnackBar(
                                      context,
                                      'Export Successful. PDF saved at: $pdfPath',
                                      Icon(Iconsax.tick_square,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiary),
                                      true);
                                } catch (e) {
                                  SnackBarCollection().errorSnackBar(
                                      context,
                                      'Error exporting data: $e',
                                      Icon(Iconsax.danger5,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onError),
                                      true);
                                }
                              } else {
                                if (filenameAndPath[0] == "") {
                                  SnackBarCollection().errorSnackBar(
                                      context,
                                      'Filename cannot be empty',
                                      Icon(Iconsax.danger5,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onError),
                                      true);
                                } else if (filenameAndPath[1] == "") {
                                  SnackBarCollection().errorSnackBar(
                                      context,
                                      "No save location selected. Please choose a folder to save the exported PDF.",
                                      Icon(Iconsax.danger5,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onError),
                                      true);
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            elevation: 7,
                            fixedSize: const Size(45, 45),
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
                              Iconsax.export_3,
                              size: 19,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      MyTooltip(
                        tooltipText: 'Import',
                        distance: 15,
                        child: ElevatedButton(
                          onPressed: () async {
                            var books = await _handleGetAllBooks();
                            var projectBooks = await _handleGetAllProjectBooks(
                                currentProjectName);

                            final allItems = <String>{
                              ...books,
                              ...projectBooks
                            }; // union of both lists
                            final projectBooksSet =
                                Set<String>.from(projectBooks);

                            final booksMap = HashMap<String, bool>();

                            for (var item in allItems) {
                              booksMap[item] = projectBooksSet.contains(item);
                            }

                            PopupDialogs().showImportBookInProjectPopupDialog(
                                context, currentProjectName, booksMap,
                                (selectedBooks) {
                              return _handleImportBookButtonPress(
                                  currentProjectName, selectedBooks);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            elevation: 7,
                            fixedSize: const Size(45, 45),
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
                              size: 23,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    logoImagePath: 'assets/images/FYP_Logo.png',
                    onLogoPress: () => _handleProjectButtonPress(),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      IndexedStack(
                        index: _selectedIndex,
                        children: [
                          // Force ManageProjectsPage to rebuild every time it's selected -- 0
                          ManageProjectsPage(
                            key: UniqueKey(),
                            importHadithFile: _handleGlobalImportButtonPress,
                          ),

                          // Dashboard Page -- 1
                          Stack(
                            children: [
                              AnimatedOpacity(
                                  opacity: _selectedIndex == dashboardPageIndex
                                      ? 1.0
                                      : 0.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: DashboardPage(
                                    key:
                                        _selectedIndex == manageProjectPageIndex
                                            ? UniqueKey()
                                            : const ValueKey('DashboardPage'),
                                    projectName: currentProjectName,
                                    onToggleTheme: widget.onToggleTheme,
                                    projectButtonOnPressed:
                                        _handleProjectButtonPress,
                                  )),
                            ],
                          ),

                          // Semantic Search Page -- 2
                          Stack(
                            children: [
                              AnimatedOpacity(
                                opacity:
                                    _selectedIndex == semanticSearchPageIndex
                                        ? 1.0
                                        : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: SemanticSearchPage(
                                  key: _selectedIndex == manageProjectPageIndex
                                      ? const ValueKey('SemanticSearchPage')
                                      : _semanticSearchKey,
                                  projectName: currentProjectName,
                                  onToggleTheme: widget.onToggleTheme,
                                  projectButtonOnPressed:
                                      _handleProjectButtonPress,
                                  selectedIndex: _selectedIndex,
                                  pageIndex: semanticSearchPageIndex,
                                ),
                              ),
                            ],
                          ),

                          // Narrators Page -- 3
                          Stack(
                            children: [
                              AnimatedOpacity(
                                opacity: _selectedIndex == narratorsPageIndex
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: NarratorsPage(
                                  key: _selectedIndex == manageProjectPageIndex
                                      ? const ValueKey('NarratorsPage')
                                      : _narratorPageKey,
                                  projectName: currentProjectName,
                                  onToggleTheme: widget.onToggleTheme,
                                  projectButtonOnPressed:
                                      _handleProjectButtonPress,
                                  selectedIndex: _selectedIndex,
                                  pageIndex: narratorsPageIndex,
                                ),
                              ),
                            ],
                          ),

                          // Narrator Details Page -- 4
                          Stack(
                            children: [
                              AnimatedOpacity(
                                opacity:
                                    _selectedIndex == narratorDetailsPageIndex
                                        ? 1.0
                                        : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: HadithNarratorDetailsPage(
                                  name: isHadithDetails
                                      ? selectedHadith
                                      : narratorDetailsName,
                                  projectName: currentProjectName,
                                  narratedData: narratedHadiths,
                                  narratorTeachersStudents:
                                      narratorTeachersStudents,
                                  sanad: sanad,
                                  details: isHadithDetails
                                      ? hadithDetails
                                      : narratorDetails,
                                  key: UniqueKey(),
                                  onBack: () {
                                    if (_prevSelectedIndex ==
                                        semanticSearchPageIndex) {
                                      _changePage(semanticSearchPageIndex);
                                    } else if (_prevSelectedIndex ==
                                        narratorsPageIndex) {
                                      _changePage(narratorsPageIndex);
                                    }
                                  },
                                  isHadith: isHadithDetails,
                                ),
                              ),
                            ],
                          ),

                          // All Hadith Page -- 5
                          Stack(
                            children: [
                              AnimatedOpacity(
                                opacity: _selectedIndex == allHadithPageIndex
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(milliseconds: 700),
                                child: AllHadithPage(
                                  key: _selectedIndex == manageProjectPageIndex
                                      ? const ValueKey('AllHadithPage')
                                      : GlobalKey(),
                                ),
                              ),
                            ],
                          ),

                          // All Narrators Page -- 7
                          Stack(
                            children: [
                              AnimatedOpacity(
                                opacity: _selectedIndex == allNarratorPageIndex
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(milliseconds: 700),
                                child: AllNarratorPage(
                                  key: _selectedIndex == manageProjectPageIndex
                                      ? const ValueKey('AllNarratorPage')
                                      : GlobalKey(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
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
                          size: 22,
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
