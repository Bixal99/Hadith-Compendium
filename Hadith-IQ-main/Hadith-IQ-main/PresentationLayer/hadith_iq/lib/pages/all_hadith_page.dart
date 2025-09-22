// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hadith_iq/api/hadith_api.dart';
import 'package:hadith_iq/api/network_helper.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:hadith_iq/components/paginated_expansion_list.dart';
import 'package:iconsax/iconsax.dart';

class AllHadithPage extends StatefulWidget {
  const AllHadithPage({
    super.key,
  });

  @override
  State<AllHadithPage> createState() => AllHadithPageState();
}

class AllHadithPageState extends State<AllHadithPage> {
  final HadithService _hadithService = HadithService();
  List<String> _allHadiths = [];
  Future<List<String>>? allHadithFuture;
  int pageNumForAllHadith = 1;
  int pageLimitForAllHadith = 1;
  bool showWelcomeContent = true;
  final GlobalKey importButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (isServerOnline()) {
        if (mounted) {
          setState(() {
            allHadithFuture = _fetchAllHadith(pageNumForAllHadith);
          });
        }
      }
    });
  }

  // Method to get All hadith
  Future<List<String>> _fetchAllHadith(int pageNumForAllHadith) async {
    try {
      Map<String, dynamic> response =
          await _hadithService.getAllHadiths(pageNumForAllHadith);
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
      List<String> newHadiths = await _fetchAllHadith(pageNumForAllHadith);

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
        Positioned.fill(
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
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                _allHadiths = snapshot.data!;
                final List<String> arrangedResult =
                    arrangeSearchResult(_allHadiths);
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 15, right: 10, left: 10),
                  child: PaginatedExpansionTileList(
                    resultList: arrangedResult,
                    itemsPerPage: 25,
                    isHadithDetails: false,
                    showLoadMore: true,
                    onReload: () {
                      setState(() {
                        if (pageNumForAllHadith < pageLimitForAllHadith) {
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
                      'No Hadith Available!',
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
