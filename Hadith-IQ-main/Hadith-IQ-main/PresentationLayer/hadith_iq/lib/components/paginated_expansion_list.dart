import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadith_iq/components/hover_elevated_button.dart';
import 'package:hadith_iq/components/hover_icon_button.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:iconsax/iconsax.dart';

class PaginatedExpansionTileList extends StatefulWidget {
  final List<String> resultList;
  final List<String> subHeadingTextListInTile;
  final int itemsPerPage;
  final bool isDeletable;
  final bool isSelectable;
  final bool isHeading;
  final bool isSaveable;
  final bool showItemDetailsInTile;
  final bool showItemSubHeadingInTile;
  final bool isHadithDetails;
  final bool showResponseTime;
  // to make refresh button load more,
  // its behavior will change and will be available only when the page is last
  final bool showLoadMore;
  final bool disableReload;
  final String headingText;
  final String subHeadingInTile;
  final double? responseTime;
  final VoidCallback? onReload;
  final void Function(String)? onDetails;
  final void Function(String)? onSingleSave;
  final void Function(String)? onSingleDelete;
  final void Function(List<String>)? onMultipleSave;
  final void Function(List<String>)? onMultipleDelete;

  const PaginatedExpansionTileList({
    super.key,
    required this.resultList,
    this.itemsPerPage = 5,
    this.isDeletable = false,
    this.isSelectable = false,
    this.isHeading = false,
    this.isSaveable = false,
    this.showLoadMore = false,
    this.showItemDetailsInTile = false,
    this.showItemSubHeadingInTile = false,
    this.showResponseTime = false,
    this.disableReload = false,
    this.isHadithDetails = true,
    this.onDetails,
    this.onSingleSave,
    this.headingText = '',
    this.subHeadingInTile = '',
    this.subHeadingTextListInTile = const [],
    this.responseTime,
    this.onSingleDelete,
    this.onMultipleDelete,
    this.onReload,
    this.onMultipleSave,
  });

  @override
  State<PaginatedExpansionTileList> createState() =>
      PaginatedExpansionTileListState();
}

class PaginatedExpansionTileListState extends State<PaginatedExpansionTileList>
    with TickerProviderStateMixin {
  int currentPage = 0;
  late List<String> searchResults;
  late final int itemsPerPage;
  late List<AnimationController> _animationControllers;
  late List<ExpansionTileController> _expansionTileControllers;
  late List<bool> selectSingleItem;
  late bool selectAllItems = false;
  Set<int> copiedIndexes = {};
  late int selectedItemsCount = 0;
  late int allItemsCount = 0;
  // to keep track when a new narrator come in sorting
  bool isNarratorChange = false;
  String lastSortedNarratorName = "";
  List<String> deleteItemsList = [];
  List<int> itemNumber = [];
  List<bool> _isExpandedList = [];
  List<String> _cleanedResult = [];

  @override
  void initState() {
    super.initState();
    itemsPerPage = widget.itemsPerPage;
    searchResults = List.from(widget.resultList);
    _cleanedResult = searchResults
        .map((result) => result.replaceAll(RegExp(r"\s*\(.*?\)$"), ""))
        .toList();
    selectSingleItem = List.generate(searchResults.length, (index) => false);
    selectedItemsCount = selectSingleItem.length;
    allItemsCount = searchResults.length;
    // Initialize animation controllers and expansion tile controllers
    _initializeAnimationControllers();
    _initializeExpansionTileControllers();
    _isExpandedList = List.generate(searchResults.length, (index) => false);
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Initialize the animation controllers
  void _initializeAnimationControllers() {
    _animationControllers = List.generate(
      searchResults.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Initialize the expansion tile controllers
  void _initializeExpansionTileControllers() {
    _expansionTileControllers = List.generate(
      searchResults.length,
      (index) => ExpansionTileController(),
    );
  }

  // Get the paginated items for the current page
  List<String> get paginatedResults {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, searchResults.length);
    return searchResults.sublist(startIndex, endIndex);
  }

  // Delete item and animate the removal
  void deleteItem(int index) {
    int globalIndex = currentPage * itemsPerPage + index;

    if (globalIndex < 0 || globalIndex >= _animationControllers.length) return;

    AnimationController controller = _animationControllers[globalIndex];

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _disposeControllerSafely(globalIndex);
          searchResults.removeAt(globalIndex);
          _cleanedResult.removeAt(index);
          allItemsCount = searchResults.length;
          selectSingleItem.removeAt(globalIndex);
          _animationControllers.removeAt(globalIndex);
          _expansionTileControllers.removeAt(globalIndex);
        });
      }
    });
    deleteItemsList.clear();
  }

  // Delete selected items and animate the removal
  void deleteSelectedItems() {
    if (!mounted) return;

    // Collect global indices of selected items.
    List<int> globalIndicesToRemove = [];
    for (int i = selectSingleItem.length - 1; i >= 0; i--) {
      if (selectSingleItem[i]) {
        globalIndicesToRemove.add(currentPage * itemsPerPage + i);
      }
    }
    if (globalIndicesToRemove.isEmpty) return;

    // Sort indices in descending order to avoid index shifting issues.
    globalIndicesToRemove.sort((a, b) => b.compareTo(a));

    setState(() {
      for (int index in globalIndicesToRemove) {
        // Remove from searchResults if index is valid.
        if (index >= 0 && index < searchResults.length) {
          searchResults.removeAt(index);
          _cleanedResult.removeAt(index);
        }
        // Remove the selection flag.
        if (index >= 0 && index < selectSingleItem.length) {
          selectSingleItem.removeAt(index);
        }
        // Dispose and remove the animation controller.
        if (index >= 0 && index < _animationControllers.length) {
          _animationControllers[index].dispose();
          _animationControllers.removeAt(index);
        }
      }
      // Reinitialize the expansion tile controllers for the remaining items.
      // Note: Do not call dispose() on these controllers if they don't have a dispose method.
      _expansionTileControllers = List.generate(
        searchResults.length,
        (index) =>
            ExpansionTileController(), // Replace with your controller initialization if needed.
      );
      selectAllItems = false;
      allItemsCount = searchResults.length;
    });
    deleteItemsList.clear();
  }

  void _disposeControllerSafely(int index) {
    if (index >= 0 && index < _animationControllers.length) {
      AnimationController controller = _animationControllers[index];

      if (controller.status != AnimationStatus.dismissed &&
          controller.status != AnimationStatus.completed) {
        controller.dispose();
      }
    }
  }

  // Extract similarity and narrator info
  String _extractSimilarity(String fullHadith) {
    if (fullHadith.contains("Similarity")) {
      return fullHadith.split("Similarity:")[1].split(")")[0].trim();
    }
    return "0%";
  }

  String _extractNarratorName(String fullHadith) {
    if (fullHadith.contains("narratorName:")) {
      return fullHadith
          .split("narratorName:")[1]
          .split("(Similarity")[0]
          .trim();
    }
    return "";
  }

  // Create SlideTransition for the animation
  Widget _buildAnimatedItem(String item, int index) {
    int globalIndex = currentPage * itemsPerPage + index;
    AnimationController controller = _animationControllers[globalIndex];
    Animation<Offset> animation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    // when narrator name change in narrator filter
    if (isNarratorChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            isNarratorChange = false;
          });
        }
      });
    }

    // Extract similarity and narrator name
    String similarityString = _extractSimilarity(item);
    String narratorName = _extractNarratorName(item);
    if (narratorName != "" && narratorName != lastSortedNarratorName) {
      isNarratorChange = true;
      lastSortedNarratorName = narratorName;
    }
    String matn = item.split(", narratorName")[0];
    matn = matn.replaceAll(RegExp(r"\s*\(.*?\)$"), "");

    // Container(
    //             decoration: BoxDecoration(
    //               color: Theme.of(context).colorScheme.surface,
    //               border: Border.all(
    //                 color: Theme.of(context).colorScheme.secondary,
    //                 width: 0.5,
    //               ),
    //               borderRadius: const BorderRadius.all(Radius.circular(15)),
    //             ),
    //             child: Padding(
    //               padding: const EdgeInsets.all(12.0),
    //               child: Directionality(
    //                 textDirection: TextDirection.rtl, // Ensures RTL layout
    //                 child: Text(
    //                   narratorName,
    //                   style: TextStyle(
    //                       fontSize: 14,
    //                       fontWeight: FontWeight.w600,
    //                       color: Theme.of(context).colorScheme.onSurface),
    //                   maxLines: 1,
    //                   overflow: TextOverflow.ellipsis,
    //                 ),
    //               ),
    //             ),
    //           )

    return SlideTransition(
      position: animation,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
              width: 0.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ExpansionTile(
                shape: Border.all(color: Colors.transparent),
                controller: _expansionTileControllers[globalIndex],
                trailing: widget.isSelectable
                    ? Transform.scale(
                        scale: 0.7,
                        child: Checkbox(
                          value: selectSingleItem[globalIndex],
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                deleteItemsList
                                    .add(_cleanedResult[globalIndex]);
                              } else {
                                deleteItemsList
                                    .remove(_cleanedResult[globalIndex]);
                              }
                              selectSingleItem[globalIndex] = value ?? false;
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
                title: Text(
                  _isExpandedList[globalIndex] ? "" : matn,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onExpansionChanged: (value) =>
                    setState(() => _isExpandedList[globalIndex] = value),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SelectableText(
                          matn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (widget.showItemDetailsInTile)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Similarity: $similarityString",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                if (narratorName.isNotEmpty)
                                  Text(
                                    "Narrator Name: $narratorName",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (widget.showItemSubHeadingInTile)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: SelectableText.rich(
                                      maxLines: 2,
                                      TextSpan(
                                        text: widget.subHeadingInTile,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: widget
                                                .subHeadingTextListInTile[index],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.normal,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.isHadithDetails)
                              AnimatedHoverElevatedButton(
                                defaultIcon: Iconsax.document_text,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverIcon: Iconsax.document_text5,
                                onPressed: () => widget.onDetails?.call(matn),
                                iconSize: 24,
                                text: "Details",
                                isTextBelow: true,
                              ),
                            if (widget.isSaveable && widget.isDeletable)
                              AnimatedHoverElevatedButton(
                                defaultIcon: Icons.bookmark_add_outlined,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverIcon: Icons.bookmark_add_rounded,
                                onPressed: () => widget.onSingleSave
                                    ?.call(_cleanedResult[globalIndex]),
                                iconSize: 24,
                                text: "Save",
                                isTextBelow: true,
                              ),
                            if (widget.isDeletable)
                              AnimatedHoverElevatedButton(
                                defaultIcon: Icons.delete_outline_rounded,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverIcon: Icons.delete_rounded,
                                onPressed: () {
                                  widget.onSingleDelete
                                      ?.call(_cleanedResult[globalIndex]);
                                  deleteItem(globalIndex);
                                },
                                iconSize: 24,
                                text: "Delete",
                                isTextBelow: true,
                              ),
                            AnimatedHoverElevatedButton(
                              defaultIcon: copiedIndexes.contains(index)
                                  ? Iconsax.copy_success
                                  : Iconsax.copy,
                              defaultColor:
                                  Theme.of(context).colorScheme.primary,
                              hoverColor: Theme.of(context).colorScheme.primary,
                              hoverIcon: copiedIndexes.contains(index)
                                  ? Iconsax.copy_success5
                                  : Iconsax.copy5,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: matn));
                                SnackBarCollection().successSnackBar(
                                    context,
                                    "Copied to clipboard",
                                    Icon(Iconsax.tick_square,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onTertiary),
                                    true);
                                setState(() {
                                  copiedIndexes.add(index);
                                });

                                Future.delayed(const Duration(seconds: 30), () {
                                  if (mounted) {
                                    setState(() {
                                      copiedIndexes.remove(index);
                                    });
                                  }
                                });
                              },
                              iconSize: 24,
                              text: copiedIndexes.contains(index)
                                  ? "Copied"
                                  : "Copy",
                              isTextBelow: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 40, right: 30, top: 10, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 25),
                  if (widget.isSelectable)
                    Tooltip(
                      message: "Select All",
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 12),
                      waitDuration: const Duration(milliseconds: 300),
                      child: Transform.scale(
                        scale: 0.7,
                        child: Checkbox(
                          value: selectAllItems,
                          onChanged: (bool? value) {
                            setState(() {
                              selectAllItems = value ?? false;
                              if (selectAllItems) {
                                selectSingleItem.fillRange(
                                    currentPage * itemsPerPage,
                                    allItemsCount -
                                                (currentPage * itemsPerPage) <
                                            itemsPerPage
                                        ? allItemsCount
                                        : ((currentPage * itemsPerPage) +
                                            itemsPerPage),
                                    true);
                                deleteItemsList = _cleanedResult;
                              } else {
                                selectSingleItem.fillRange(
                                    currentPage * itemsPerPage,
                                    allItemsCount -
                                                (currentPage * itemsPerPage) <
                                            itemsPerPage
                                        ? allItemsCount
                                        : ((currentPage * itemsPerPage) +
                                            itemsPerPage),
                                    false);
                                deleteItemsList.clear();
                              }
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  if (selectSingleItem.where((item) => item == true).length >=
                      2) ...[
                    Text(
                      "${selectSingleItem.where((value) => value == true).length} Selected",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Tooltip(
                        message: "Delete Selected",
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 12),
                        waitDuration: const Duration(milliseconds: 300),
                        child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: AnimatedHoverIconButton(
                              defaultIcon: Icons.delete_outline_rounded,
                              hoverIcon: Icons.delete_rounded,
                              size: 20,
                              defaultColor:
                                  Theme.of(context).colorScheme.error,
                              hoverColor: Theme.of(context).colorScheme.error,
                              onPressed: () {
                                widget.onMultipleDelete
                                    ?.call(deleteItemsList);
                                deleteSelectedItems();
                                deleteItemsList.clear();
                              },
                            )),
                      ),
                    ),
                  ],
                  if (widget.isSaveable)
                    Tooltip(
                      message: (selectSingleItem
                              .where((item) => item == true)
                              .isNotEmpty)
                          ? "Save Selected"
                          : "Save All",
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 12),
                      waitDuration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: AnimatedHoverIconButton(
                          defaultIcon: Icons.bookmark_add_outlined,
                          hoverIcon: Icons.bookmark_add_rounded,
                          size: 20,
                          defaultColor: Theme.of(context).colorScheme.primary,
                          hoverColor: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            List<String> toSaveList = [];
                            if (selectSingleItem
                                .where((item) => item == true)
                                .isNotEmpty) {
                              for (int index = 0;
                                  index < searchResults.length;
                                  ++index) {
                                int globalIndex =
                                    currentPage * itemsPerPage + index;
                                if (globalIndex >= 0 &&
                                    globalIndex < searchResults.length) {
                                  if (selectSingleItem[globalIndex]) {
                                    toSaveList
                                        .add(_cleanedResult[globalIndex]);
                                  }
                                }
                              }
                              widget.onMultipleSave?.call(toSaveList);
                            } else {
                              widget.onMultipleSave?.call(_cleanedResult);
                            }
                          },
                        ),
                      ),
                    ),
                  widget.showLoadMore &&
                          (currentPage + 1) * itemsPerPage <
                              searchResults.length
                      ? Tooltip(
                          message: "Load More",
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 12,
                          ),
                          waitDuration: const Duration(milliseconds: 300),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: AnimatedHoverIconButton(
                                defaultIcon: Icons.refresh_rounded,
                                hoverIcon: Icons.rotate_right_rounded,
                                size: 20,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverColor:
                                    Theme.of(context).colorScheme.primary,
                                onPressed: widget.onReload,
                                isDisabled: widget.disableReload ||
                                    (widget.showLoadMore &&
                                        (currentPage + 1) * itemsPerPage <
                                            searchResults.length)),
                          ),
                        )
                      : Tooltip(
                          message: "Refresh",
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 12,
                          ),
                          waitDuration: const Duration(milliseconds: 300),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: AnimatedHoverIconButton(
                                defaultIcon: Icons.refresh_rounded,
                                hoverIcon: Icons.rotate_right_rounded,
                                size: 20,
                                defaultColor:
                                    Theme.of(context).colorScheme.primary,
                                hoverColor:
                                    Theme.of(context).colorScheme.primary,
                                onPressed: widget.onReload,
                                isDisabled: widget.disableReload ||
                                    (widget.showLoadMore &&
                                        (currentPage + 1) * itemsPerPage <
                                            searchResults.length)),
                          ),
                        ),
                  if (widget.showResponseTime)
                    Text(
                      "Response time: ${widget.responseTime!.toStringAsFixed(2)}s",
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              Row(
                children: [
                  Text(
                    searchResults.isEmpty
                        ? "No Hadiths Found"
                        : "Showing ${currentPage * itemsPerPage + 1} - ${((currentPage + 1) * itemsPerPage) > allItemsCount ? allItemsCount : (currentPage + 1) * itemsPerPage} of $allItemsCount",
                    style: const TextStyle(fontSize: 12),
                  ),
                  IconButton(
                    onPressed: currentPage > 0
                        ? () {
                            setState(() {
                              selectSingleItem.fillRange(
                                  0, selectSingleItem.length, false);
                              selectAllItems = false;
                              currentPage--;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 15,
                      color: currentPage > 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                    ),
                  ),
                  IconButton(
                    onPressed: (currentPage + 1) * itemsPerPage <
                            searchResults.length
                        ? () {
                            setState(() {
                              selectSingleItem.fillRange(
                                  0, selectSingleItem.length, false);
                              selectAllItems = false;
                              currentPage++;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: (currentPage + 1) * itemsPerPage <
                              searchResults.length
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              )
            ],
          ),
        ),
        if (widget.isHeading) ...[
          Divider(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            thickness: 0.5,
            indent: 50,
            endIndent: 60,
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 45, right: 45, top: 5, bottom: 5),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.only(
                    left: 15, right: 15, top: 10, bottom: 10),
                // decoration: BoxDecoration(
                //   // color: Theme.of(context).colorScheme.secondary,
                //   border: Border.all(
                //     color: Theme.of(context).colorScheme.secondary,
                //     width: 1.5,
                //   ),
                //   borderRadius: BorderRadius.circular(15),
                // ),
                child: Row(
                  children: [
                    Text.rich(
                      TextSpan(
                          text: "يبحث : ",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900),
                          children: [
                            TextSpan(
                                text: widget.headingText.length >= 150
                                    ? "${widget.headingText.substring(0, 150)}..."
                                    : widget.headingText,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal))
                          ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                itemCount: paginatedResults.length,
                itemBuilder: (context, index) {
                  return Directionality(
                      textDirection: TextDirection.rtl,
                      child:
                          _buildAnimatedItem(paginatedResults[index], index));
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
