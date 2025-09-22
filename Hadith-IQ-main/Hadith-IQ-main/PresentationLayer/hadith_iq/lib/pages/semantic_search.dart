// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hadith_iq/api/hadith_api.dart';
import 'package:hadith_iq/api/project_api.dart';
import 'package:hadith_iq/components/basic_app_bar.dart';
import 'package:hadith_iq/components/hover_icon_button.dart';
import 'package:hadith_iq/components/paginated_expansion_list.dart';
import 'package:hadith_iq/components/popup_dialogs.dart';
import 'package:hadith_iq/components/search_bar.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:hadith_iq/provider/hadith_details_notifier.dart';
import 'package:hadith_iq/widget_extras.dart/semantic_search_extra_widgets.dart';
import 'package:iconsax/iconsax.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

class SemanticSearchPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String projectName; // Project name passed from the grid
  final VoidCallback projectButtonOnPressed;
  final int selectedIndex;
  final int pageIndex;

  const SemanticSearchPage(
      {super.key,
      required this.projectName,
      required this.onToggleTheme,
      required this.projectButtonOnPressed,
      required this.selectedIndex,
      required this.pageIndex});

  @override
  State<SemanticSearchPage> createState() => SemanticSearchPageState();
}

class SemanticSearchPageState extends State<SemanticSearchPage> {
  // ---------------- Local Variables ----------------
  final ProjectService _projectService = ProjectService();
  final HadithService _hadithService = HadithService();
  late String _currentProjectName;
  TextEditingController searchController =
      TextEditingController(); // controller for Searchbar
  // bool showText = true;
  List<String> _searchResults = [];
  List<String> _localSearchResults = [];
  List<String> _localMatnResults = [];
  List<String> _allHadiths = [];
  Future<List<String>>? searchFuture; // For managing the Search Future state
  Future<List<String>>?
      savedQueryResultFuture; // For managing the Search Future state
  Future<List<String>>?
      allHadithFuture; // For managing the all hadith Future state
  bool searchingResult = false;
  double selectedThreshold = 0.9; // Default value (90%)
  bool sortByNarrator = false;
  bool sortByAuthenticity = false;
  String authenticityOption = "None";
  bool isSearchBarFocused =
      false; // This will track focus state of the search bar
  List<String> _savedQueries = [];
  final Map<int, GlobalKey> _savedQueryMenuButtonKeys =
      {}; // Store keys for each saved query menu button
  final GlobalKey<PaginatedExpansionTileListState>
      _paginatedExpansionTileListStatekey = GlobalKey();
  final GlobalKey<MySearchBarState> _mySearchBarStatekey = GlobalKey();
  final _savedQueriesController = StreamController<List<String>>.broadcast();

  Stream<List<String>> get savedQueriesStream => _savedQueriesController.stream;
  bool _showSavedQuery = false;
  int _savedQueryClickedIndex = 0;
  bool isSearched = false;
  bool isFetchedAllHadiths = false;
  String _searchedQuery = "";
  int pageNumForAllHadith = 1;
  int pageLimitForAllHadith = 1;
  double? responseTime; // in seconds
  late DateTime startTime;
  bool isRootBaseSearch = false;
  String? _selectedOperator;
  final List<String> _operators = ['', 'AND', 'OR', 'XOR'];
  String? operatorToAdd;
  int currentSearchType = 0;

  // ---------------------------------------------

  // ---------------- Constructor ----------------
  @override
  void initState() {
    super.initState();
    _currentProjectName = widget.projectName;
    sortByAuthenticity = false;
    sortByNarrator = false;
    selectedThreshold = 0.9;
  }

  @override
  void didUpdateWidget(SemanticSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Fetch hadiths only when the page becomes visible for the first time
    if (widget.selectedIndex == widget.pageIndex &&
        allHadithFuture == null &&
        !isFetchedAllHadiths) {
      setState(() {
        allHadithFuture ??=
            _fetchAllHadith(_currentProjectName, pageNumForAllHadith);
        isFetchedAllHadiths = true;
      });
    }
  }

  // ---------------------------------------------

  // ---------------- Helper Methods ----------------

  // Method to get All hadith
  Future<List<String>> _fetchAllHadith(
      String projectName, int pageNumForAllHadith) async {
    try {
      Map<String, dynamic> response = await _hadithService.getAllProjectHadiths(
          projectName, pageNumForAllHadith);
      if (response.containsKey("results") && response["results"] is List) {
        pageLimitForAllHadith = response["totalPages"];
        return response["results"]
            .map<String>(
                (hadith) => hadith["matn"].toString()) // Extract "matn"
            .toList();
      } else {
        SnackBarCollection().errorSnackBar(
          context,
          "Hadiths field is null or missing!",
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    } catch (e) {
      SnackBarCollection().errorSnackBar(
        context,
        'Error fetching all hadith: $e',
        Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
        false,
      );
    }
    return [];
  }

  Future<void> _fetchAndAppendAllHadith() async {
    try {
      List<String> newHadiths =
          await _fetchAllHadith(_currentProjectName, pageNumForAllHadith);

      setState(() {
        _allHadiths.addAll(newHadiths);
      });
    } catch (e) {
      SnackBarCollection().errorSnackBar(
        context,
        'Error fetching all hadith: $e',
        Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
        false,
      );
    }
  }

  // Method to get hadith details
  Future<List<List<String>>> _fetchHadithDetails(
      String matn, String projectName) async {
    try {
      Map<String, dynamic> response =
          await _hadithService.getHadithDetails(matn, projectName);
      if (response.containsKey("sanads") && response["sanads"] is List) {
        var books =
            List<String>.from(response["books"].map((e) => e.toString()));
        var allResult = response["sanads"]
            .map<dynamic>((narrators) => narrators["narrators"]
                .map<dynamic>((narratorName) => narratorName['narrator_name']))
            .toList();
        List<String> narratorList = [];
        for (var item in allResult) {
          var dynamicList = item.map((i) => i).toList();
          narratorList = dynamicList.map<String>((i) => i.toString()).toList();
        }
        return [books, narratorList];
      } else {
        SnackBarCollection().errorSnackBar(
          context,
          "Results field is null or missing!",
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    } catch (e) {
      SnackBarCollection().errorSnackBar(
        context,
        'Error fetching all hadith: $e',
        Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
        false,
      );
    }
    return [[], []];
  }

  void _initializeSavedQueriesHoverKeys() {
    // Ensure all keys are initialized
    _savedQueryMenuButtonKeys.clear();
    for (int i = 0; i < _savedQueries.length; i++) {
      _savedQueryMenuButtonKeys[i] = GlobalKey();
    }
  }

  Future<void> _fetchSavedQueries() async {
    try {
      final newQueries =
          await _projectService.getProjectState(_currentProjectName);

      if (_savedQueries != newQueries) {
        _savedQueries = newQueries;
        _savedQueriesController.add(_savedQueries);
      }

      _initializeSavedQueriesHoverKeys();
    } catch (e) {
      SnackBarCollection().errorSnackBar(
        context,
        "Error fetching saved queries: $e",
        Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
        false,
      );
    }
  }

  // Method to get saved query result
  Future<List<String>> _fetchSavedQueryResult(
      String projectName, String query) async {
    try {
      Map<String, dynamic> response =
          await _projectService.getSingleProjectState(projectName, query);
      if (response.containsKey("stateData")) {
        return List<String>.from(response["stateData"]);
      }
    } catch (e) {
      SnackBarCollection().errorSnackBar(
        context,
        'Error fetching saved query result: $e',
        Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
        false,
      );
    }
    return [];
  }

  void _deleteHadithFromSavedQuery(
      String projectName, String queryName, List<String> matn) async {
    try {
      var response = await _projectService.removeHadithFromStateQuery(
          projectName, queryName, matn);
      if (response['status']) {
        SnackBarCollection().successSnackBar(
            context,
            response['message'],
            Icon(Iconsax.tick_square,
                color: Theme.of(context).colorScheme.onTertiary),
            true);
        setState(() {
          savedQueryResultFuture = _fetchSavedQueryResult(
            _currentProjectName,
            queryName,
          );
        });
      }
    } catch (e) {
      SnackBarCollection().errorSnackBar(
          context,
          'Error deleting matn from query: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
      setState(() {
        savedQueryResultFuture = _fetchSavedQueryResult(
          _currentProjectName,
          queryName,
        );
      });
    }
  }

  void _saveHadithInSavedQuery(List<String> hadiths) async {
    {
      try {
        var response = await _projectService.saveProjectState(
            _currentProjectName, _searchedQuery, hadiths);
        if (response['status']) {
          SnackBarCollection().successSnackBar(
              context,
              response['message'],
              Icon(Iconsax.tick_square,
                  color: Theme.of(context).colorScheme.onTertiary),
              true);
          _fetchSavedQueries();
        }
      } catch (e) {
        SnackBarCollection().errorSnackBar(
            context,
            "Failed to save query: $e",
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            true);
      }
    }
  }

  Future<List<List<String>>> getSemanticallySearchedHadiths() async {
    List<String> list =
        _paginatedExpansionTileListStatekey.currentState?.paginatedResults ??
            [];

    if (list.isNotEmpty) {
      List<String> transformedList = list.map((item) {
        String matn = item.split(", narratorName")[0];
        return matn.replaceAll(RegExp(r"\s*\(.*?\)$"), "");
      }).toList();

      List<String> result = [_searchedQuery];
      result.addAll(transformedList);

      final List<String> sanadStrings =
          await getEachHadithSanad(transformedList);
      return [result, sanadStrings];
    }

    return [];
  }

  Future<List<String>> getFilenameAndPathToExport() async {
    Completer<List<String>> completer = Completer<List<String>>();

    PopupDialogs().exportDataPopupDialog(context, (filename, filepath) {
      List<String> list = [
        filename.isEmpty ? "" : filename,
        filepath.isEmpty ? "" : filepath
      ];
      completer.complete(list);
    });

    return completer.future;
  }

  Future<List<String>> getEachHadithSanad(List<String> matn) async {
    try {
      final List<Map<String, dynamic>> results =
          await _hadithService.getListOfHadithDetails(matn);

      List<String> sanadStrings = [];
      for (var hadith in results) {
        // sanads.add(hadith['sanads'] ?? []);
        var sanad = hadith['sanads'] ?? [];
        if (sanad is List) {
          if (sanad.length >= 2) {
            // Use second sanad only
            var secondSanad = sanad[1];
            if (secondSanad is Map && secondSanad.containsKey('narrators')) {
              var narrators = secondSanad['narrators'];
              if (narrators is List) {
                final names = narrators
                    .map((n) => n['narrator_name'] as String)
                    .join(', ');
                sanadStrings.add(names);
              }
            }
          } else if (sanad.length == 1) {
            // Use the only sanad available
            var onlySanad = sanad[0];
            if (onlySanad is Map && onlySanad.containsKey('narrators')) {
              var narrators = onlySanad['narrators'];
              if (narrators is List) {
                final names = narrators
                    .map((n) => n['narrator_name'] as String)
                    .join(', ');
                sanadStrings.add(names);
              }
            }
          }
        } else {
          SnackBarCollection().errorSnackBar(
            context,
            'Unexpected sanad format',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
      }
      return sanadStrings;
    } catch (e) {
      SnackBarCollection().errorSnackBar(
        context,
        'Error fetching each Hadith details: $e',
        Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
        false,
      );
      return [];
    }
  }

  // Method to perform a search
  Future<List<String>> performSearch(String query, String projectName,
      double threshold, int searchType) async {
    if (query.isNotEmpty) {
      setState(() {
        responseTime = 0.0;
        startTime = DateTime.now();
      });
      try {
        List<String> results;
        if (searchType == 2) {
          final List<String> rslt =
              await _hadithService.searchHadithsByString(query, projectName);
          results = rslt;
        } else if (searchType == 1) {
          final List<String> rslt =
              await _hadithService.searchHadithsByOperators(query, projectName);
          results = rslt;
        } else {
          results = await _hadithService.fetchSemanticSearchResults(
              query, projectName, threshold);
        }
        final endTime = DateTime.now();
        final elapsed = endTime.difference(startTime).inMilliseconds / 1000.0;

        setState(() {
          responseTime = elapsed;
        });
        return results;
      } catch (e) {
        SnackBarCollection().errorSnackBar(
            context,
            'Error fetching search results: $e',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false);
        return [];
      }
    } else {
      SnackBarCollection().errorSnackBar(
          context,
          'Query cannot be empty.',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
      return [];
    }
  }

  // Method to arrange search results
  List<String> arrangeSearchResult(List<String> list) {
    final List<String> formattedResults = list.map((result) {
      // Check if the result contains similarity
      if (result.contains("similarity:")) {
        // Check if narratorName exists
        if (result.contains("narratorName:")) {
          final match = RegExp(
                  r"\{'matn':\s*'(.*?)',\s*'narratorName':\s*'(.*?)',\s*'similarity':\s*([\d.]+)\}")
              .firstMatch(result);

          if (match != null) {
            final hadith = match.group(1); // Extract the Hadith text
            final similarity =
                double.parse(match.group(2)!); // Extract similarity
            final similarityPercentage = (similarity * 100).toStringAsFixed(2);
            final narratorName = match
                .group(3)
                ?.trim(); // Extract and trim narratorName if present

            // Return formatted string including narratorName if it exists
            if (narratorName != null && narratorName.isNotEmpty) {
              return '$hadith (Narrator: $narratorName, Similarity: $similarityPercentage%)';
            }

            // Return formatted string without narratorName
            return '$hadith (Similarity: $similarityPercentage%)';
          }
        }

        // If narratorName does not exist, just return the similarity info
        final match = RegExp(r'matn:\s*(.*?)\s*,\s*similarity:\s*([\d.]+)')
            .firstMatch(result);

        if (match != null) {
          final hadith = match.group(1); // Extract the Hadith text
          final similarity =
              double.parse(match.group(2)!); // Extract similarity
          final similarityPercentage = (similarity * 100).toStringAsFixed(2);

          // Return formatted string
          return '$hadith (Similarity: $similarityPercentage%)';
        }
      }
      // If fails, return original result
      return result;
    }).toList();

    return formattedResults;
  }

  // Method to expand search results
  Future<List<String>> expandSearch(
      List<String> query, String projectName, double threshold) async {
    if (query.isNotEmpty) {
      try {
        final List<String> results = await _hadithService
            .fetchExpandSearchResults(query, projectName, threshold);
        return results;
      } catch (e) {
        SnackBarCollection().errorSnackBar(
            context,
            'Error fetching expand results: $e',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false);
        return [];
      }
    } else {
      SnackBarCollection().errorSnackBar(
          context,
          'Search result cannot be empty.',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
      return [];
    }
  }

  // Method to sort the search results
  Future<List<String>> sortResult(
      List<String> query, bool byNarrator, bool byAuthenticity) async {
    if (query.isNotEmpty) {
      try {
        final List<String> results = await _hadithService.sortResult(
            query, byNarrator, byAuthenticity, "");
        return results;
      } catch (e) {
        SnackBarCollection().errorSnackBar(
            context,
            'Error fetching sort results: $e',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false);
        throw Exception('Error fetching sort results: $e');
      }
    } else {
      SnackBarCollection().errorSnackBar(
          context,
          'Result list cannot be empty.',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
    }
    return [];
  }

  // Method to clear the search results
  void clearResults() {
    setState(() {
      sortByAuthenticity = false;
      sortByNarrator = false;
      selectedThreshold = 0.9;
      searchingResult = false;
      searchController.clear();
      _searchResults = [];
      _localSearchResults = [];
      isSearched = false;
      //_allHadiths = [];
    });
  }

  // Method to show the popover menu for saved queries
  void _showPopoverSavedQuery(BuildContext context, int index) {
    // Use the button's context (via its GlobalKey) to anchor the popover
    final BuildContext buttonContext =
        _savedQueryMenuButtonKeys[index]!.currentContext!;
    showPopover(
      context: buttonContext, // Use the button's context
      bodyBuilder: (bodyBuilderContext) => SavedQueryPopupMenuItems(
        onMergePressed: () => PopupDialogs().showMergeQueriesPopupDialog(
            context, _savedQueries, _savedQueries[index],
            (mergedQueryName, mergedQueriesList) async {
          var response = await _projectService.mergeProjectState(
              _currentProjectName, mergedQueryName, mergedQueriesList);
          if (response['status']) {
            SnackBarCollection().successSnackBar(
                context,
                response['message'],
                Icon(Iconsax.tick_square,
                    color: Theme.of(context).colorScheme.onTertiary),
                true);
            _fetchSavedQueries();
          } else {
            SnackBarCollection().errorSnackBar(
                context,
                "Failed to merge project state",
                Icon(Iconsax.danger5,
                    color: Theme.of(context).colorScheme.onError),
                true);
          }
          Navigator.pop(bodyBuilderContext);
        }),
        onRenamePressed: () => PopupDialogs().renameItemPopupDialog(
          context,
          index,
          _savedQueries[index],
          (renameController) async {
            final newName = renameController.text.trim();
            final oldName = _savedQueries[index];
            if (newName.isNotEmpty) {
              var response = await _projectService.renameProjectState(
                  _currentProjectName, oldName, newName);
              if (response['status']) {
                setState(() {
                  _savedQueries[index] = newName;
                });
                SnackBarCollection().successSnackBar(
                    context,
                    response['message'],
                    Icon(Iconsax.tick_square,
                        color: Theme.of(context).colorScheme.onTertiary),
                    true);
                _fetchSavedQueries();
              } else {
                SnackBarCollection().errorSnackBar(
                    context,
                    "Failed to rename project state",
                    Icon(Iconsax.danger5,
                        color: Theme.of(context).colorScheme.onError),
                    true);
              }
            }
            Navigator.pop(bodyBuilderContext);
          },
        ),
        onDeletePressed: () => PopupDialogs().deleteItemPopupDialog(
            context, index, _savedQueries[index], "Saved Query", () async {
          var response = await _projectService.deleteProjectState(
              _currentProjectName, _savedQueries[index]);

          if (response['status']) {
            setState(() {
              _savedQueries.removeAt(index);
            });
            SnackBarCollection().successSnackBar(
                context,
                response['message'],
                Icon(Iconsax.tick_square,
                    color: Theme.of(context).colorScheme.onTertiary),
                true);
            _fetchSavedQueries();
          } else {
            SnackBarCollection().errorSnackBar(
                context,
                "Failed to delete project state",
                Icon(Iconsax.danger5,
                    color: Theme.of(context).colorScheme.onError),
                true);
          }
          Navigator.pop(bodyBuilderContext);
        }),
      ),
      height: 185,
      width: 125,
      backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
      direction: PopoverDirection.top,
      barrierColor: Colors.transparent,
      radius: 12,
    );
  }

  void _showPopoverSearchBarSettings(BuildContext context) {
    // Use the search bar's context (via its GlobalKey) to anchor the popover
    final currentContext = _mySearchBarStatekey.currentContext;

    if (currentContext != null) {
      final BuildContext buttonContext = currentContext;
      showPopover(
          context: buttonContext, // Use the button's context
          bodyBuilder: (bodyBuilderContext) => SearchBarSettingsMenu(
                defaultSelectedRadioButton: currentSearchType,
                onTypeSelected: (selectedType, index) {
                  if (Navigator.of(context).canPop() &&
                      currentSearchType != index) {
                    Navigator.of(context).maybePop();
                  }
                  setState(() {
                    currentSearchType = index;
                  });
                  if (selectedType == "Root Base") {
                    setState(() {
                      isRootBaseSearch = true;
                    });
                  } else {
                    setState(() {
                      isRootBaseSearch = false;
                    });
                  }
                },
                types: const ["Semantically", "Root Base", "String Base"],
              ),
          height: 115,
          width: 125,
          backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
          direction: PopoverDirection.top,
          barrierColor: Colors.transparent,
          radius: 12);
    }
  }

  Widget _buildSavedQueriesList(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 7, left: 2, bottom: 10),
        child: ListView.builder(
          key: ValueKey(
              _savedQueries.length), // Forces rebuild when list changes
          itemCount: _savedQueries.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return SavedQueryListItem(
              query: _savedQueries[index],
              index: index,
              onMenuPressed: (index) => _showPopoverSavedQuery(context, index),
              onTap: (index) {
                setState(() {
                  _savedQueryClickedIndex = index;
                  _showSavedQuery = true;
                  savedQueryResultFuture = _fetchSavedQueryResult(
                    _currentProjectName,
                    _savedQueries[index],
                  );
                });
              },
              buttonKey: _savedQueryMenuButtonKeys[index]!,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResultList(BuildContext context) {
    return Expanded(
      child: isSearched
          ? FutureBuilder<List<String>>(
              future: searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  if (_localSearchResults.isNotEmpty) {
                    _searchResults = _localSearchResults;
                  } else {
                    searchingResult = false;
                    sortByAuthenticity = false;
                    sortByNarrator = false;
                    selectedThreshold = 0.9;
                  }
                  SnackBarCollection().errorSnackBar(
                      context,
                      snapshot.error.toString(),
                      Icon(Iconsax.danger5,
                          color: Theme.of(context).colorScheme.onError),
                      false);
                  return const SizedBox();
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  _searchResults = snapshot.data!;
                  if (_localSearchResults.isEmpty) {
                    _localSearchResults = _searchResults;
                    if (_localSearchResults.isEmpty) {
                      SnackBarCollection().errorSnackBar(
                          context,
                          "No Hadith Found for query in project '$_currentProjectName'",
                          Icon(Iconsax.danger5,
                              color: Theme.of(context).colorScheme.onError),
                          false);
                    }
                  }
                  final List<String> arrangedResult =
                      arrangeSearchResult(_searchResults);
                  _localMatnResults.clear();
                  _localMatnResults = arrangedResult
                      .map(
                        (result) => result.replaceAll(
                          RegExp(r"\s*\(.*?\)$"),
                          "",
                        ),
                      )
                      .toList();
                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: PaginatedExpansionTileList(
                      key: _paginatedExpansionTileListStatekey,
                      resultList: arrangedResult,
                      itemsPerPage: 20,
                      isDeletable: true,
                      isSaveable: true,
                      isSelectable: true,
                      showItemDetailsInTile: true,
                      onDetails: (matn) async {
                        var list = await _fetchHadithDetails(
                            matn, _currentProjectName);
                        List<String> sanad = list[1];
                        String books = list[0].join(', ');
                        Provider.of<HadithDetailsProvider>(context,
                                listen: false)
                            .setHadithDetails(matn, sanad, books);
                      },
                      onSingleDelete: (p0) {
                        _searchResults.removeWhere((item) => item.contains(p0));
                        _localSearchResults
                            .removeWhere((item) => item.contains(p0));
                      },
                      onMultipleDelete: (p0) {
                        for (var item1 in p0) {
                          _searchResults
                              .removeWhere((item) => item.contains(item1));
                          _localSearchResults
                              .removeWhere((item) => item.contains(item1));
                        }
                      },
                      onSingleSave: (toSaveItem) {
                        _saveHadithInSavedQuery([toSaveItem]);
                      },
                      onMultipleSave: (toSaveList) {
                        _saveHadithInSavedQuery(toSaveList);
                      },
                      showResponseTime: true,
                      responseTime: responseTime,
                    ),
                  );
                } else {
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
                        'No Hadith Found!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ));
                }
              },
            )
          : Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.find_in_page_rounded,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  size: 100,
                ),
                const SizedBox(height: 15),
                Text(
                  "Search for the Hadiths you seek!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest),
                ),
              ],
            )),
    );
  }

  Widget _buildSavedQueryResultList(BuildContext context, String headingText) {
    return SavedQueryResultList(
      savedQueryResultFuture: savedQueryResultFuture,
      headingText: headingText,
      onHadithDetails: (matn) async {
        var list = await _fetchHadithDetails(matn, _currentProjectName);
        List<String> sanad = list[1];
        String books = list[0].join(', ');
        Provider.of<HadithDetailsProvider>(context, listen: false)
            .setHadithDetails(matn, sanad, books);
      },
      onSingleDelete: (singleMatnToDelete) {
        _deleteHadithFromSavedQuery(
            _currentProjectName, headingText, [singleMatnToDelete]);
      },
      onMultipleDelete: (multipleMatnToDelete) {
        _deleteHadithFromSavedQuery(
            _currentProjectName, headingText, multipleMatnToDelete);
      },
    );
  }

  // ---------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              MyBasicAppBar(
                onToggleTheme: widget.onToggleTheme,
                projectName: _currentProjectName,
                projectButtonOnPressed: widget.projectButtonOnPressed,
              ),
              // Search Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 25,
                children: [
                  MySearchBar(
                    hintText: 'Search Hadiths',
                    searchController: searchController,
                    onSubmitted: (query) {
                      setState(() {
                        searchingResult = true;
                        _showSavedQuery = false;
                        isSearched = true;
                        _localSearchResults = [];
                        _searchedQuery = query;
                        searchFuture = performSearch(
                            query, _currentProjectName, selectedThreshold, currentSearchType);
                      });
                    },
                    isWithLastIcon: true,
                    lastIcon: Iconsax.setting_5,
                    lastIconKey: _mySearchBarStatekey,
                    onLastIconPressed: () {
                      _showPopoverSearchBarSettings(context);
                    },
                    tooltipText: "Search Type",
                    onFocusChanged: (isFocused) {
                      setState(() {
                        if (_savedQueries.isEmpty) {
                          _fetchSavedQueries();
                        }
                        isSearchBarFocused = true;
                      });
                    },
                  ),
                  if (isRootBaseSearch)
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.75),
                            blurRadius: 7,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 15,
                          children: [
                            DropdownButton<String>(
                              value: _selectedOperator,
                              items: _operators.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value.isEmpty ? null : value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedOperator = newValue;
                                });
                              },
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondary),
                              borderRadius: BorderRadius.circular(25),
                              dropdownColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                color: _selectedOperator == null
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _selectedOperator == null
                                  ? null
                                  : () {
                                      setState(() {
                                        operatorToAdd = _selectedOperator;
                                        if (operatorToAdd != null) {
                                          String prevText =
                                              searchController.text;
                                          searchController.text =
                                              "$prevText (${operatorToAdd!}) ";
                                        }
                                      });
                                    },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              if (!isSearchBarFocused && !searchingResult)
                Expanded(
                  child: FutureBuilder<List<String>>(
                    key: ValueKey(_allHadiths.length),
                    future: allHadithFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        SnackBarCollection().errorSnackBar(
                            context,
                            snapshot.error.toString(),
                            Icon(Iconsax.danger5,
                                color: Theme.of(context).colorScheme.onError),
                            false);
                        return const SizedBox();
                      } else if (snapshot.hasData &&
                          snapshot.data!.isNotEmpty) {
                        _allHadiths = snapshot.data!;
                        // print(_allHadiths);
                        final List<String> arrangedResult =
                            arrangeSearchResult(_allHadiths);

                        // _localMatnResults.clear();
                        // _localMatnResults = arrangedResult
                        //     .map(
                        //       (result) => result.replaceAll(
                        //         RegExp(r"\s*\(.*?\)$"),
                        //         "",
                        //       ),
                        //     )
                        //     .toList();
                        // print(_localMatnResults);
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: PaginatedExpansionTileList(
                            resultList: arrangedResult,
                            itemsPerPage: 25,
                            onDetails: (matn) async {
                              var list = await _fetchHadithDetails(
                                  matn, _currentProjectName);
                              List<String> sanad = list[1];
                              String books = list[0].join(', ');
                              Provider.of<HadithDetailsProvider>(context,
                                      listen: false)
                                  .setHadithDetails(matn, sanad, books);
                            },
                            showLoadMore: true,
                            onReload: () {
                              setState(() {
                                if (pageNumForAllHadith <
                                    pageLimitForAllHadith) {
                                  pageNumForAllHadith++;
                                }
                              });
                              if (pageNumForAllHadith <= 4) {
                                _fetchAndAppendAllHadith();
                              } else {
                                SnackBarCollection().errorSnackBar(
                                  context,
                                  "Limit Exceeded, Need to offload!",
                                  Icon(Iconsax.danger5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onError),
                                  false,
                                );
                              }
                            },
                          ),
                        );
                      } else {
                        return Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dnd_forwardslash_outlined, // Warning icon
                              color: Theme.of(context).colorScheme.error,
                              size: 60.0,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'No Hadith Available!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface // Text color
                                  ),
                            ),
                          ],
                        ));
                      }
                    },
                  ),
                ),
              if (isSearchBarFocused || searchingResult)
                Flexible(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 200,
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.35),
                                  offset: const Offset(5, 5),
                                ),
                                BoxShadow(
                                    blurRadius: 5,
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    offset: const Offset(-7, 0)),
                                BoxShadow(
                                    blurRadius: 5,
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    offset: const Offset(0, -7)),
                              ]),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_ios_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _savedQueriesController
                                              .add(_savedQueries);
                                          isSearchBarFocused =
                                              searchingResult = false;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      iconSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Clear and Expand buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                      padding: const EdgeInsets.only(right: 7),
                                      child: ElevatedButton(
                                        onPressed: clearResults,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 25, vertical: 17),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          elevation: 5,
                                        ),
                                        child: const Text(
                                          "Reset",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _localSearchResults = [];
                                        searchFuture = expandSearch(
                                            _searchResults,
                                            _currentProjectName,
                                            selectedThreshold);
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 25, vertical: 17),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: const Text(
                                      "Expand",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 20, bottom: 20),
                                child: Divider(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  thickness: 0.5,
                                  indent: 50,
                                  endIndent: 60,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Threshold: ${(selectedThreshold * 100).toInt()}%",
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Slider(
                                    value: selectedThreshold,
                                    min: 0.1,
                                    max: 0.9,
                                    divisions: 16,
                                    label:
                                        "${(selectedThreshold * 100).toInt()}%",
                                    onChanged: (value) {
                                      setState(() {
                                        selectedThreshold = value;
                                      });
                                    },
                                    activeColor:
                                        Theme.of(context).colorScheme.primary,
                                    inactiveColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 20, bottom: 20),
                                child: Divider(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  thickness: 0.5,
                                  indent: 50,
                                  endIndent: 60,
                                ),
                              ),
                              // checkboxes for sorting
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Sort Result : ",
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 30, right: 30, top: 3),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'By Narrator',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Checkbox(
                                            value: sortByNarrator,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                sortByNarrator = value ?? false;
                                                searchFuture = sortResult(
                                                    _searchResults,
                                                    sortByNarrator,
                                                    sortByAuthenticity);
                                              });
                                            },
                                            activeColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 20, bottom: 20),
                                child: Divider(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  thickness: 0.5,
                                  indent: 50,
                                  endIndent: 60,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Saved Queries : ",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StreamBuilder<List<String>>(
                                stream: savedQueriesStream,
                                initialData: _savedQueries,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.active &&
                                      !snapshot.hasData) {
                                    return const Expanded(
                                      child: Center(
                                        child: SizedBox(
                                          width: 25,
                                          height: 25,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Expanded(
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          spacing: 7,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Icon(
                                              Iconsax.cloud_cross,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              size: 35,
                                            ),
                                            Text(
                                              'Server connection error!',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12.0,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Expanded(
                                      child: Center(
                                          child: Column(
                                        spacing: 7,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Icon(
                                            Icons.dnd_forwardslash_outlined,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            size: 35,
                                          ),
                                          Text(
                                            'No Saved Queries available!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.0,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface),
                                          ),
                                        ],
                                      )),
                                    );
                                  } else {
                                    _savedQueries = snapshot.data!;
                                    return _buildSavedQueriesList(context);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // FutureBuilder to handle loading and results
                      if (searchingResult || isSearchBarFocused)
                        _showSavedQuery
                            ? Expanded(
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 30, top: 10),
                                        child: AnimatedHoverIconButton(
                                          defaultIcon:
                                              Icons.arrow_circle_left_outlined,
                                          hoverIcon:
                                              Icons.arrow_circle_left_rounded,
                                          size: 20,
                                          defaultColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          hoverColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          onPressed: () => setState(
                                              () => _showSavedQuery = false),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                    _buildSavedQueryResultList(context,
                                        _savedQueries[_savedQueryClickedIndex])
                                  ],
                                ),
                              )
                            : _buildSearchResultList(context),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
