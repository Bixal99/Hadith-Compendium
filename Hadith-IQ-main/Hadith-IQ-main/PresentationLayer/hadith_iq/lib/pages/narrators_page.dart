import 'package:flutter/material.dart';
import 'package:hadith_iq/api/narrator_api.dart';
import 'package:hadith_iq/components/basic_app_bar.dart';
import 'package:hadith_iq/components/paginated_list.dart';
import 'package:hadith_iq/components/search_bar.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:hadith_iq/provider/narrator_item_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class NarratorsPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String projectName;
  final VoidCallback projectButtonOnPressed;
  final int selectedIndex;
  final int pageIndex;

  const NarratorsPage({
    super.key,
    required this.projectName,
    required this.onToggleTheme,
    required this.projectButtonOnPressed,
    required this.selectedIndex,
    required this.pageIndex,
  });

  @override
  State<NarratorsPage> createState() => NarratorsPageState();
}

class NarratorsPageState extends State<NarratorsPage> {
  // ---------------- Local Variables ----------------
  final NarratorService _narratorService = NarratorService();
  late String _currentProjectName;
  TextEditingController searchController =
      TextEditingController(); // controller for Searchbar
  // bool showText = true;
  List<String> searchResults = [];
  List<String> _localSearchResults = [];
  List<String> _allNarrators = [];
  Future<List<String>>? searchFuture; // For managing the Search Future state
  Future<List<String>>?
      allNarratorFuture; // For managing the Search Future state
  bool searchingResult = false;
  bool sortByNarrator = false;
  bool sortByAuthenticity = false;
  String authenticityOption = "None";
  bool isSearched = false; // This will track focus state of the search bar
  int pageNumForAllNarrators = 1;
  int pageLimitForAllNarrators = 1;
  List<List<String>> narratedHadiths = [[], []];

  // ---------------------------------------------

  // ---------------- Constructor ----------------
  @override
  void initState() {
    super.initState();
    _currentProjectName = widget.projectName;
    sortByAuthenticity = false;
    sortByNarrator = false;
  }

  @override
  void didUpdateWidget(NarratorsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Fetch narrators only when the page becomes visible for the first time
    if (widget.selectedIndex == widget.pageIndex && allNarratorFuture == null) {
      setState(() {
        allNarratorFuture =
            _fetchAllNarrator(widget.projectName, pageNumForAllNarrators);
      });
    }
  }

  // ---------------------------------------------

  // ---------------- Helper Methods ----------------

  // Method to get All narrator
  Future<List<String>> _fetchAllNarrator(
      String projectName, int pageNumForAllNarrators) async {
    try {
      Map<String, dynamic> response = await _narratorService
          .getAllProjectNarrators(projectName, pageNumForAllNarrators);
      if (response.containsKey("results") && response["results"] is List) {
        pageLimitForAllNarrators = response["totalPages"];
        List<String> list =
            response["results"].map<String>((e) => e.toString()).toList();
        return list;
      } else {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            "Narrators field is null or missing!",
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error fetching all narrator: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
    return [];
  }

  Future<void> _fetchAndAppendAllNarrator() async {
    try {
      List<String> newNarrators =
          await _fetchAllNarrator(_currentProjectName, pageNumForAllNarrators);

      setState(() {
        _allNarrators.addAll(newNarrators);
      });
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error fetching all narrator: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
  }

  Future<List<List<String>>> _fetchNarratedHadiths(
      String projectName, String narratorName) async {
    try {
      Map<String, dynamic> response =
          await _narratorService.getNarratedHadiths(projectName, narratorName);
      if (response.containsKey("results") && response["results"] is List) {
        // Safely map `matn` from the response, ensuring it's a String
        List<String> matnList =
            (response['results'] as List<dynamic>).map<String>((item) {
          // Ensure that matn is a String
          if (item['matn'] is String) {
            return item['matn'] as String;
          } else {
            return ''; // Default to empty string if it's not a String
          }
        }).toList();

        // Safely map `sanad` from the response, ensuring it's a List
        List<String> sanadList =
            (response['results'] as List<dynamic>).map<String>((item) {
          if (item is Map<String, dynamic>) {
            final sanad = item['sanad'];
            if (sanad is List) {
              return sanad.map((e) => e.toString()).join(' ----> ');
            }
            if (sanad is String) {
              String cleaned = sanad
                  .replaceAll('[', '')
                  .replaceAll(']', '')
                  .replaceAll("'", '')
                  .split(',')
                  .map((e) => e.trim())
                  .toList()
                  .reversed
                  .join(' ← ');
              return cleaned;
            }
          }
          return ''; // fallback if sanad is missing or not a List
        }).toList();
        return [matnList, sanadList];
      } else {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            "Narrated hadiths are null or missing!",
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
        return [];
      }
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error fetching narrated hadiths: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
      return [];
    }
  }

  Future<String> _fetchNarratorDetails(
      String projectName, String narratorName) async {
    try {
      List<String> response =
          await _narratorService.getNarratorDetails(projectName, narratorName);
      if (response[0] == "") {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            "Narrator details are null or missing!",
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
        return '';
      }
      return response.join(' -- ');
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error fetching narrated details: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
    return '';
  }

  Future<List<List<String>>> _fetchNarratorTeachersStudents(
      String projectName, String narratorName) async {
    try {
      List<String> teachers =
          await _narratorService.getNarratorTeachers(projectName, narratorName);
      List<String> students =
          await _narratorService.getNarratorStudents(projectName, narratorName);
      if (teachers[0] == 'Error') {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            'Error fetching narrator teachers: ${teachers[1]}',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
        return [[], []];
      } else if (students[0] == 'Error') {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            'Error fetching narrator students: ${students[1]}',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
        return [[], []];
      }
      return [teachers, students];
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error fetching narrator teachers: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
    return [[], []];
  }

  // Method to perform a search
  Future<List<String>> performSearch(String query, String projectName) async {
    if (query.isNotEmpty) {
      try {
        final List<String> results =
            await _narratorService.fetchNarratorSearchResults(query);
        return results;
      } catch (e) {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
              context,
              'Error fetching search results: $e',
              Icon(Iconsax.danger5,
                  color: Theme.of(context).colorScheme.onError),
              true);
        }
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

  // Method to perform sorting
  Future<List<String>> _sortResult(
      String projectName, List<String> narrators, bool byOrder) async {
    if (narrators.isNotEmpty) {
      try {
        final List<String> results = await _narratorService.sortNarrators(
            projectName, narrators, byOrder ? true : false, byOrder);
        return results;
      } catch (e) {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
              context,
              'Error sorting results: $e',
              Icon(Iconsax.danger5,
                  color: Theme.of(context).colorScheme.onError),
              true);
        }
        return [];
      }
    } else {
      SnackBarCollection().errorSnackBar(
          context,
          'Result list cannot be empty.',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          true);
      return [];
    }
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
              MySearchBar(
                hintText: 'Search Narrators',
                searchController: searchController,
                onSubmitted: (query) {
                  setState(() {
                    isSearched = true;
                    _localSearchResults = [];
                    searchFuture = performSearch(
                        query.replaceAll(RegExp(r'\s+'), ' ').trim(),
                        _currentProjectName);
                  });
                },
                isWithLastIcon: true,
                lastIcon: Iconsax.menu_15,
                onLastIconPressed: () {
                  setState(() {
                    isSearched = false;
                  });
                },
                tooltipText: "All Narrators",
              ),
              const SizedBox(
                height: 8,
              ),
              isSearched
                  ? Expanded(
                      child: FutureBuilder<List<String>>(
                        future: searchFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            if (_localSearchResults.isNotEmpty) {
                              searchResults = _localSearchResults;
                            } else {
                              searchingResult = false;
                              sortByAuthenticity = false;
                              sortByNarrator = false;
                            }
                            SnackBarCollection().errorSnackBar(
                                context,
                                snapshot.error.toString(),
                                Icon(Iconsax.danger5,
                                    color:
                                        Theme.of(context).colorScheme.onError),
                                false);
                            return const SizedBox();
                          } else if (snapshot.hasData &&
                              snapshot.data!.isNotEmpty) {
                            searchResults = snapshot.data!;
                            if (_localSearchResults.isEmpty) {
                              _localSearchResults = searchResults;
                            }
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: PaginatedList(
                                searchResults: _localSearchResults,
                                itemsPerPage: 25,
                                isClickable: true,
                                isSortable: true,
                                onClick: (item) async {
                                  // Fetch data and await the result
                                  List<List<String>> narratedHadiths =
                                      await _fetchNarratedHadiths(
                                          widget.projectName, item);
                                  String narratedDetails =
                                      await _fetchNarratorDetails(
                                          widget.projectName, item);

                                  List<List<String>> narratorTeachers =
                                      await _fetchNarratorTeachersStudents(
                                          widget.projectName, item);

                                  // Pass the narratedHadiths to the NarratorProvider
                                  // ignore: use_build_context_synchronously
                                  Provider.of<NarratorProvider>(context,
                                          listen: false)
                                      .setNarratorDetails(
                                          item,
                                          narratedHadiths,
                                          narratedDetails,
                                          narratorTeachers[0],
                                          narratorTeachers[1]);
                                },
                                onSort: (sortBy) {
                                  setState(() {
                                    searchFuture = _sortResult(
                                        _currentProjectName,
                                        _localSearchResults,
                                        sortBy == "Order" ? true : false);
                                  });
                                },
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
                                  'No Narrator Available!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ],
                            ));
                          }
                        },
                      ),
                    )
                  : Expanded(
                      child: FutureBuilder<List<String>>(
                        key: ValueKey(_allNarrators.length),
                        future: allNarratorFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            if (_localSearchResults.isNotEmpty) {
                              searchResults = _localSearchResults;
                            } else {
                              searchingResult = false;
                              sortByAuthenticity = false;
                              sortByNarrator = false;
                            }
                            SnackBarCollection().errorSnackBar(
                                context,
                                snapshot.error.toString(),
                                Icon(Iconsax.danger5,
                                    color:
                                        Theme.of(context).colorScheme.onError),
                                false);
                            return const SizedBox();
                          } else if (snapshot.hasData &&
                              snapshot.data!.isNotEmpty) {
                            _allNarrators = snapshot.data!;
                            List<String> uniqueList =
                                _allNarrators.toSet().toList();
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: PaginatedList(
                                searchResults: uniqueList,
                                itemsPerPage: 25,
                                isSortable: true,
                                showLoadMore: true,
                                isClickable: true,
                                onClick: (item) async {
                                  List<List<String>> narratedHadiths =
                                      await _fetchNarratedHadiths(
                                          widget.projectName, item);
                                  String narratedDetails =
                                      await _fetchNarratorDetails(
                                          widget.projectName, item);

                                  List<List<String>> narratorTeachers =
                                      await _fetchNarratorTeachersStudents(
                                          widget.projectName, item);

                                  // Pass the narratedHadiths to the NarratorProvider
                                  // ignore: use_build_context_synchronously
                                  Provider.of<NarratorProvider>(context,
                                          listen: false)
                                      .setNarratorDetails(
                                          item,
                                          narratedHadiths,
                                          narratedDetails,
                                          narratorTeachers[0],
                                          narratorTeachers[1]);
                                },
                                onReload: () {
                                  setState(() {
                                    if (pageNumForAllNarrators <
                                        pageLimitForAllNarrators) {
                                      pageNumForAllNarrators++;
                                    }
                                  });
                                  if (pageNumForAllNarrators <= 4) {
                                    _fetchAndAppendAllNarrator();
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
                                onSort: (sortBy) {
                                  setState(() {
                                    allNarratorFuture = _sortResult(
                                        _currentProjectName,
                                        uniqueList,
                                        sortBy == "Order" ? false : true);
                                  });
                                },
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
                                  'No Narrator Found!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                              ],
                            ));
                          }
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
