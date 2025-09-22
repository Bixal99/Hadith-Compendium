import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MySearchBar extends StatefulWidget {
  final String hintText;
  final TextEditingController searchController;
  final FocusNode? focusNode;
  final Function(bool)? onFocusChanged; // Callback to update the focus state
  final VoidCallback? onTap;
  final void Function(String) onSubmitted;
  final VoidCallback? onLastIconPressed;
  final bool isWithLastIcon;
  final String tooltipText;
  final IconData lastIcon;
  final GlobalKey? lastIconKey;

  const MySearchBar({
    super.key,
    required this.hintText,
    required this.searchController,
    this.onTap,
    required this.onSubmitted,
    this.onLastIconPressed,
    required this.isWithLastIcon,
    this.focusNode,
    this.onFocusChanged,
    this.tooltipText = "Default Message",
    this.lastIcon = Iconsax.menu_15,
    this.lastIconKey,
  });

  @override
  State<MySearchBar> createState() => MySearchBarState();
}

class MySearchBarState extends State<MySearchBar> {
  late FocusNode _internalFocusNode;
  bool searchBarChange = false;

  @override
  void initState() {
    super.initState();
    // Initialize _internalFocusNode either with the provided focusNode or create one internally
    _internalFocusNode = widget.focusNode ?? FocusNode();

    // Add a listener to notify focus changes
    _internalFocusNode.addListener(() {
      if (widget.onFocusChanged != null) {
        widget.onFocusChanged!(_internalFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    // Dispose the internal FocusNode only if it was created internally
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 1600
          ? 750
          : MediaQuery.of(context).size.width * 0.43,
      height: 40,
      child: Container(
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
          border: Border.all(
            color:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // SearchBar takes most of the space
            Expanded(
              child: SearchBar(
                autoFocus: false,
                elevation: WidgetStateProperty.all(0),
                textStyle: WidgetStatePropertyAll(TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
                controller: widget.searchController,
                hintText: widget.hintText,
                focusNode: _internalFocusNode,
                onChanged: (value) {
                  setState(() {
                    value.isNotEmpty
                        ? searchBarChange = true
                        : searchBarChange = false;
                  });
                },
                onSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                trailing: searchBarChange
                    ? [
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.error,
                            size: 16,
                          ),
                          onPressed: () {
                            widget.searchController.clear();
                            setState(() {
                              searchBarChange = false;
                            });
                          },
                        ),
                      ]
                    : [
                        Padding(
                          padding: const EdgeInsets.all(7),
                          child: widget.searchController.text.isEmpty
                              ? Icon(
                                  Icons.search,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                )
                              : null,
                        ),
                      ],
              ),
            ),
            // IconButton at the end of the SearchBar
            if (widget.isWithLastIcon)
              Tooltip(
                message: widget.tooltipText,
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
                  child: IconButton(
                    key: widget.lastIconKey,
                    icon: Icon(
                      widget.lastIcon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: widget.onLastIconPressed,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
