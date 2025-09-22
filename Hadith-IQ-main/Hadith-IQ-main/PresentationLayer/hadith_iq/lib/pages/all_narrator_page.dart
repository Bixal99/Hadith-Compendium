// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hadith_iq/api/narrator_api.dart';
import 'package:hadith_iq/api/network_helper.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:hadith_iq/components/paginated_list.dart';
import 'package:iconsax/iconsax.dart';

class AllNarratorPage extends StatefulWidget {
  const AllNarratorPage({
    super.key,
  });

  @override
  State<AllNarratorPage> createState() => AllNarratorPageState();
}

class AllNarratorPageState extends State<AllNarratorPage> {
  final NarratorService _narratorService = NarratorService();
  List<String> _allNarrators = [];
  Future<List<String>>? allNarratorFuture;
  int pageNumForAllNarrators = 1;
  int pageLimitForAllNarrators = 1;
  bool showWelcomeContent = true;
  final GlobalKey importButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (isServerOnline()) {
        if (mounted) {
          setState(() {
            allNarratorFuture = _fetchAllNarrator(pageNumForAllNarrators);
          });
        }
      }
    });
  }

  // Method to get All hadith
  Future<List<String>> _fetchAllNarrator(int pageNumForAllNarrators) async {
    try {
      Map<String, dynamic> response =
          await _narratorService.getAllNarrators(pageNumForAllNarrators);
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
          await _fetchAllNarrator(pageNumForAllNarrators);

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // logo in background
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomRight,
            child: ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                widthFactor: 0.65,
                heightFactor: 0.73,
                child: Opacity(
                  opacity: 0.07,
                  child: Image.asset(
                    'assets/images/FYP_Logo.png',
                    fit: BoxFit.cover,
                    width: 1000,
                    height: 650,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: FutureBuilder<List<String>>(
            key: ValueKey(_allNarrators.length),
            future: allNarratorFuture,
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
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                _allNarrators = snapshot.data!;
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10, right: 10, left: 10),
                  child: PaginatedList(
                    searchResults: _allNarrators,
                    itemsPerPage: 25,
                    showLoadMore: true,
                    onReload: () {
                      setState(() {
                        if (pageNumForAllNarrators < pageLimitForAllNarrators) {
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
                              color: Theme.of(context).colorScheme.onError),
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
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ],
                ));
              }
            },
          ),
        ),
      ],
    );
  }
}
