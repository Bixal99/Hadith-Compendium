import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadith_iq/components/hover_icon_button.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:iconsax/iconsax.dart';
import 'package:popover/popover.dart';

class PaginatedList extends StatefulWidget {
  final List<String> searchResults;
  final int itemsPerPage;
  final bool isDeletable;
  final VoidCallback? onReload;
  final bool showLoadMore;
  final bool isSortable;
  final bool isClickable;
  final void Function(String)? onClick;
  final void Function(String)? onSort;

  const PaginatedList({
    super.key,
    required this.searchResults,
    this.itemsPerPage = 5,
    this.isDeletable = false,
    this.onReload,
    this.showLoadMore = false,
    this.isSortable = false,
    this.isClickable = false,
    this.onClick, this.onSort,
  });

  @override
  State<PaginatedList> createState() => _PaginatedListState();
}

class _PaginatedListState extends State<PaginatedList>
    with TickerProviderStateMixin {
  int currentPage = 0;
  late List<String> searchResults;
  late final int itemsPerPage;
  late List<bool> selectSingleItem;
  late bool selectAllItems = false;
  Set<int> copiedIndexes = {};
  late int selectedItemsCount = 0;
  late int allItemsCount = 0;
  int? hoveredListItemIndex;
  final GlobalKey sortItemsButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    itemsPerPage = widget.itemsPerPage;
    searchResults =
        List.from(widget.searchResults); // Copy to allow modifications
    selectSingleItem = List.generate(searchResults.length, (index) => false);
    selectedItemsCount = selectSingleItem.length;
    allItemsCount = searchResults.length;
  }

  // Get the paginated items for the current page
  List<String> get paginatedResults {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, searchResults.length);
    return searchResults.sublist(startIndex, endIndex);
  }

  void _showPopover() {
    // Use the button's context (via its GlobalKey) to anchor the popover
    final BuildContext buttonContext = sortItemsButtonKey.currentContext!;
    showPopover(
      context: buttonContext,
      bodyBuilder: (context) => SortNarratorsDropdownMenuItems(
        byAuthenticityButtonPressed: () {
          widget.onSort?.call("Order");
          Navigator.pop(context);
        },
        byNarratorButtonPressed: () {
          widget.onSort?.call("Authenticity");
          Navigator.pop(context);
        },
      ),
      height: 95,
      width: 145,
      backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
      direction: PopoverDirection.bottom,
      barrierColor: Colors.transparent,
      radius: 12,
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
                  const SizedBox(width: 20),
                  if (widget.isSortable)
                    Tooltip(
                      message: "Sort Results",
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
                          key: sortItemsButtonKey,
                          defaultIcon: Iconsax.sort,
                          hoverIcon: Iconsax.sort5,
                          size: 22,
                          defaultColor: Theme.of(context).colorScheme.primary,
                          hoverColor: Theme.of(context).colorScheme.primary,
                          onPressed: _showPopover,
                        ),
                      ),
                    ),
                  widget.showLoadMore &&
                          (currentPage + 1) * itemsPerPage <
                              searchResults.length
                      ? Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: AnimatedHoverIconButton(
                            defaultIcon: Icons.refresh_rounded,
                            hoverIcon: Icons.rotate_right_rounded,
                            size: 20,
                            defaultColor:
                                Theme.of(context).colorScheme.primary,
                            hoverColor: Theme.of(context).colorScheme.primary,
                            onPressed: widget.onReload,
                            isDisabled: widget.showLoadMore &&
                                (currentPage + 1) * itemsPerPage <
                                    searchResults.length,
                          ),
                        )
                      : Tooltip(
                          message:
                              widget.showLoadMore ? "Load More" : "Refresh",
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
                              isDisabled: widget.showLoadMore &&
                                  (currentPage + 1) * itemsPerPage <
                                      searchResults.length,
                            ),
                          ),
                        ),
                ],
              ),
              Row(
                children: [
                  Text(
                    searchResults.isEmpty
                        ? "Nothing Found"
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
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.builder(
                itemCount: paginatedResults.length,
                itemBuilder: (context, index) {
                  return MouseRegion(
                    onEnter: (_) =>
                        setState(() => hoveredListItemIndex = index),
                    onExit: (_) =>
                        setState(() => hoveredListItemIndex = null),
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: widget.isClickable
                          ? () {
                              widget.onClick?.call(paginatedResults[index]);
                            }
                          : () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                              color: hoveredListItemIndex == index
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.25)
                                  : Theme.of(context).colorScheme.surface,
                              border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.secondary,
                                width: 0.5,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.25),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Text(
                                      paginatedResults[index],
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 7),
                                    child: AnimatedHoverIconButton(
                                      defaultIcon:
                                          copiedIndexes.contains(index)
                                              ? Iconsax.copy_success
                                              : Iconsax.copy,
                                      defaultColor: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      hoverColor: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      hoverIcon: copiedIndexes.contains(index)
                                          ? Iconsax.copy_success5
                                          : Iconsax.copy5,
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: paginatedResults[index]));
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
            
                                        Future.delayed(
                                            const Duration(seconds: 60), () {
                                          if (mounted) {
                                            setState(() {
                                              copiedIndexes.remove(index);
                                            });
                                          }
                                        });
                                      },
                                      size: 16,
                                      constraints: const BoxConstraints(),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SortNarratorsDropdownMenuItems extends StatelessWidget {
  final VoidCallback byAuthenticityButtonPressed;
  final VoidCallback byNarratorButtonPressed;
  const SortNarratorsDropdownMenuItems(
      {super.key,
      required this.byAuthenticityButtonPressed,
      required this.byNarratorButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            SizedBox(
              width: 130,
              child: ElevatedButton(
                  onPressed: byNarratorButtonPressed,
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
                            "Order Descending",
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
              width: 130,
              child: ElevatedButton(
                  onPressed: byAuthenticityButtonPressed,
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
                          Iconsax.verify,
                          size: 22,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            "Order Ascending",
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
