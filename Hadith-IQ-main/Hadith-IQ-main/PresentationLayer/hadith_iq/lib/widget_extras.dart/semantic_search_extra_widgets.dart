import 'package:flutter/material.dart';
import 'package:hadith_iq/components/paginated_expansion_list.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:iconsax/iconsax.dart';

class SavedQueryPopupMenuItems extends StatelessWidget {
  final VoidCallback onMergePressed;
  final VoidCallback onRenamePressed;
  final VoidCallback onDeletePressed;

  const SavedQueryPopupMenuItems(
      {super.key,
      required this.onMergePressed,
      required this.onRenamePressed,
      required this.onDeletePressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            SizedBox(
              width: 110,
              child: ElevatedButton(
                  onPressed: onMergePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
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
                          Iconsax.hierarchy_2,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 13),
                          child: Text(
                            "Merge",
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
                  onPressed: onRenamePressed,
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
                          Icons.drive_file_rename_outline_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            "Rename",
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
                  onPressed: () {},
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
                          Iconsax.export_3,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            "Export",
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
                  onPressed: onDeletePressed,
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
                          width: 9,
                        ),
                        Icon(
                          Icons.delete_rounded,
                          size: 22,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Text(
                            "Delete",
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ])),
            ),
          ],
        ));
  }
}

class SavedQueryListItem extends StatefulWidget {
  final String query;
  final int index;
  final Function(int) onTap;
  final Function(int) onMenuPressed;
  final GlobalKey buttonKey;

  const SavedQueryListItem({
    super.key,
    required this.query,
    required this.index,
    required this.onTap,
    required this.onMenuPressed,
    required this.buttonKey,
  });

  @override
  SavedQueryListItemState createState() => SavedQueryListItemState();
}

class SavedQueryListItemState extends State<SavedQueryListItem> {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);

  @override
  void dispose() {
    _isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(widget.index),
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHovered,
          builder: (context, isHovered, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: isHovered
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10,
                  children: [
                    Expanded(
                      child: Text(
                        widget.query,
                        style: TextStyle(
                          color: isHovered
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                    Tooltip(
                      message: "Options",
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 12),
                      waitDuration: const Duration(milliseconds: 300),
                      child: IconButton(
                        key: widget.buttonKey,
                        icon: Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: isHovered
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => widget.onMenuPressed(widget.index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SavedQueryResultList extends StatelessWidget {
  final Future<List<String>>? savedQueryResultFuture;
  final String headingText;
  final void Function(String)? onHadithDetails;
  final void Function(String)? onSingleDelete;
  final void Function(List<String>)? onMultipleDelete;

  const SavedQueryResultList({
    super.key,
    required this.savedQueryResultFuture,
    required this.headingText,
    required this.onHadithDetails,
    this.onSingleDelete,
    this.onMultipleDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FutureBuilder<List<String>>(
        future: savedQueryResultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            SnackBarCollection().errorSnackBar(
              context,
              snapshot.error.toString(),
              Icon(Iconsax.danger5,
                  color: Theme.of(context).colorScheme.onError),
              false,
            );
            return const SizedBox();
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<String> savedResult = List<String>.from(snapshot.data ?? []);
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: PaginatedExpansionTileList(
                resultList: savedResult,
                itemsPerPage: 20,
                isDeletable: true,
                isSelectable: true,
                // onDetails: (matn) => onHadithDetails?.call(matn),
                onDetails: onHadithDetails,
                onSingleDelete: onSingleDelete,
                onMultipleDelete: onMultipleDelete,
                isHeading: true,
                headingText: headingText,
              ),
            );
          } else {
            return _buildNoDataFound(context);
          }
        },
      ),
    );
  }

  /// Separate method for the "No Hadith Found" UI
  Widget _buildNoDataFound(BuildContext context) {
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
            'No Hadith Found!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchBarSettingsMenu extends StatefulWidget {
  final void Function(String selectedType, int index) onTypeSelected;
  final List<String> types;
  final int defaultSelectedRadioButton;
  const SearchBarSettingsMenu(
      {super.key,
      required this.onTypeSelected,
      required this.types,
      required this.defaultSelectedRadioButton});

  @override
  State<SearchBarSettingsMenu> createState() => _SearchBarSettingsMenuState();
}

class _SearchBarSettingsMenuState extends State<SearchBarSettingsMenu> {
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.defaultSelectedRadioButton;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTypeSelected(widget.types[_selectedValue],_selectedValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          children: List.generate(widget.types.length, (index) {
            return Row(
              children: [
                Radio<int>(
                    value: index,
                    groupValue: _selectedValue,
                    onChanged: (int? value) {
                      setState(() {
                        _selectedValue = value!;
                      });
                      widget.onTypeSelected(widget.types[index],_selectedValue);
                    },
                    activeColor: Theme.of(context).colorScheme.onSecondary,
                    fillColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.primary;
                        }
                        return Theme.of(context).colorScheme.onSecondary;
                      },
                    )),
                Text(
                  widget.types[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
