// ignore_for_file: use_build_context_synchronously

import 'dart:collection';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadith_iq/components/import_narrator_dialog.dart';
import 'package:iconsax/iconsax.dart';

class PopupDialogs {
  void deleteItemPopupDialog(BuildContext context, int index, String itemName,
      String itemType, VoidCallback deleteDialogButtonPress) {
    if (itemType == "") {
      itemType = "Project";
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
            child: Dialog(
              backgroundColor: Theme.of(layoutContext).colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Delete $itemType",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(layoutContext).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          text: "Are you sure you want to delete ",
                          style: TextStyle(
                            color:
                                Theme.of(layoutContext).colorScheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: "'$itemName'?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(layoutContext)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(layoutContext).colorScheme.onPrimary,
                              foregroundColor:
                                  Theme.of(layoutContext).colorScheme.primary,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(layoutContext)
                                      .colorScheme
                                      .primary,
                                  width: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              fixedSize: const Size(110, 35),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              deleteDialogButtonPress();
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
                                  color: Theme.of(layoutContext)
                                      .colorScheme
                                      .onPrimary,
                                  width: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              fixedSize: const Size(110, 35),
                            ),
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void renameItemPopupDialog(
      BuildContext context,
      int index,
      String currentName,
      Function(TextEditingController) renameDialogButtonPress) {
    final TextEditingController renameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      barrierDismissible: true,
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
              title: const Text(
                "Rename Project",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: TextField(
                  controller: renameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    label: Text("New Name"),
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(40),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
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
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        fixedSize: const Size(110, 35),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        renameDialogButtonPress(
                            renameController); // Pass the updated name
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(layoutContext).colorScheme.primary,
                        foregroundColor:
                            Theme.of(layoutContext).colorScheme.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color:
                                Theme.of(layoutContext).colorScheme.onPrimary,
                            width: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        fixedSize: const Size(110, 35),
                      ),
                      child: const Text(
                        "Rename",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void exportDataPopupDialog(
      BuildContext context, Function(String, String) onSubmit) {
    String selectedFolderPath = "";
    final TextEditingController filenameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
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
                  "Export PDF",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: TextField(
                  controller: filenameController,
                  decoration: InputDecoration(
                    label: const Text(
                      "File Name",
                      style: TextStyle(fontSize: 14),
                    ),
                    border: const OutlineInputBorder(),
                    hintStyle: const TextStyle(fontSize: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.folder_open,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: "Choose Folder",
                      onPressed: () async {
                        String? path =
                            await FilePicker.platform.getDirectoryPath();
                        if (path != null) {
                          selectedFolderPath = path;
                        }
                      },
                    ),
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(26),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
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
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        fixedSize: const Size(110, 35),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onSubmit(filenameController.text,
                            selectedFolderPath); // Pass the file name
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(layoutContext).colorScheme.primary,
                        foregroundColor:
                            Theme.of(layoutContext).colorScheme.onPrimary,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color:
                                Theme.of(layoutContext).colorScheme.onPrimary,
                            width: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        fixedSize: const Size(110, 35),
                      ),
                      child: const Text(
                        "Export",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Method to show a dialog for merging queries
  void showMergeQueriesPopupDialog(
      BuildContext context,
      List<String> savedQueries,
      String queryName,
      Function(String, List<String>) mergeQueriesCallback) {
    List<String> filteredQueries =
        savedQueries.where((query) => query != queryName).toList();
    List<bool> selectedItems =
        List.generate(filteredQueries.length, (index) => false);
    Set<String> selectedQueries = {};
    bool editMergeQueryName = false;
    TextEditingController controller = TextEditingController();
    String mergingQueryName = "Merging query with $queryName";
    bool showError = false;
    bool checkSameQueryMergeName = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (BuildContext dialogContext) {
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
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Theme.of(layoutContext).colorScheme.surface,
            child: StatefulBuilder(
              builder: (statefulBuilderContext, setState) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (MediaQuery.of(layoutContext).size.height < 650) {
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                  }
                });

                return Container(
                  height: 600,
                  width: 500,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close Button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: Theme.of(layoutContext)
                                    .colorScheme
                                    .primary),
                            onPressed: () => Navigator.pop(dialogContext),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ),

                      // Title
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Merge Queries",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(layoutContext).colorScheme.onSurface,
                          ),
                        ),
                      ),

                      // Merging Query Name
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 10),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min, // Prevent unbounded width
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Merge Query Name: ",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(layoutContext)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            editMergeQueryName
                                ? Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: TextField(
                                            controller: controller,
                                            autofocus: true,
                                            onSubmitted: (newValue) {
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.check,
                                              size: 20,
                                              color: Theme.of(layoutContext)
                                                  .colorScheme
                                                  .primary),
                                          onPressed: () {
                                            setState(() {
                                              mergingQueryName =
                                                  controller.text;
                                              if (mergingQueryName ==
                                                  queryName) {
                                                checkSameQueryMergeName = true;
                                                showError = true;
                                              } else {
                                                checkSameQueryMergeName =
                                                    showError =
                                                        editMergeQueryName =
                                                            false;
                                              }
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  )
                                : Flexible(
                                    child: Text(
                                      mergingQueryName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Theme.of(layoutContext)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            if (!editMergeQueryName)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    controller = TextEditingController(
                                        text: mergingQueryName);
                                    editMergeQueryName = true;
                                  });
                                },
                                icon: Icon(Icons.edit,
                                    size: 14,
                                    color: Theme.of(layoutContext)
                                        .colorScheme
                                        .primary),
                              ),
                          ],
                        ),
                      ),

                      // Query Name
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: "Query: ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(layoutContext)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: queryName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Theme.of(layoutContext)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1, // adjust max lines as needed
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Merging Queries Display
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 10, bottom: 10, right: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text("Merge with: ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(layoutContext)
                                        .colorScheme
                                        .onSurface,
                                  )),
                            ),
                            Flexible(
                              child: SelectableText(
                                selectedQueries.isEmpty
                                    ? "None selected"
                                    : selectedQueries.join(", "),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(layoutContext)
                                      .colorScheme
                                      .onSurface,
                                ),
                                textAlign: TextAlign.start,
                                cursorColor:
                                    Theme.of(layoutContext).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showError)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 7,
                            children: [
                              Icon(
                                Iconsax.danger5,
                                color:
                                    Theme.of(layoutContext).colorScheme.error,
                                size: 20,
                              ),
                              Text(
                                checkSameQueryMergeName
                                    ? "Merge query name cannot be same as Query!"
                                    : "Select atleast one query to merge with!",
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(layoutContext).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // List of Queries with Checkboxes
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(layoutContext)
                                      .colorScheme
                                      .secondary,
                                  width: 0.5), // Border around the list
                              borderRadius:
                                  BorderRadius.circular(12), // Rounded corners
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredQueries.length,
                                itemBuilder: (context, index) {
                                  return Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: CheckboxListTile(
                                      title: SelectableText(
                                        filteredQueries[index].length >= 70
                                            ? "${filteredQueries[index].substring(0, 70)}..."
                                            : filteredQueries[index],
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                        textAlign: TextAlign.start,
                                        cursorColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      value: selectedItems[index],
                                      onChanged: (bool? value) {
                                        setState(() {
                                          selectedItems[index] = value!;
                                          if (value) {
                                            showError = false;
                                            selectedQueries
                                                .add(filteredQueries[index]);
                                          } else {
                                            selectedQueries
                                                .remove(filteredQueries[index]);
                                          }
                                        });
                                      },
                                      checkboxScaleFactor: 0.7,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Merge Button
                      ElevatedButton(
                        onPressed: () {
                          if (selectedQueries.toList().isEmpty) {
                            setState(() => showError = true);
                          } else {
                            var list = selectedQueries.toList()..add(queryName);
                            mergeQueriesCallback(mergingQueryName, list);
                            if (Navigator.canPop(dialogContext)) {
                              Navigator.pop(dialogContext);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(layoutContext).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.merge_type,
                                size: 18,
                                color: Theme.of(layoutContext)
                                    .colorScheme
                                    .onPrimary,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 11),
                                child: Text(
                                  "Merge",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(layoutContext)
                                          .colorScheme
                                          .onPrimary,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ]),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });
      },
    );
  }

  // Method to show a dialog for importing narrator details
  void showImportNarratorDetailsPopupDialog(
      BuildContext context, String bookName, String filePath) {
    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => ImportNarratorOverlay(
        bookName: bookName,
        filePath: filePath,
        onClose: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      ),
    );

    overlayState.insert(overlayEntry);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;

      if (screenSize.width < 1200 || screenSize.height < 650) {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      }
    });
  }

  void showAboutDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AboutDialog',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final mediaSize = MediaQuery.of(context).size;

        // Dynamically close if screen is too small
        if (mediaSize.height < 650 || mediaSize.width < 1200) {
          Future.microtask(() {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });
        }

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // Blur effect
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    maxHeight: 410,
                    minWidth: 280,
                    minHeight: 400,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Logo/Icon
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 34,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'About This Software',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),

                        // Content
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'This software was developed by:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Syed Ali Masood\n• Malaika Tariq',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Special thanks to our supervisor:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Dr. Affan Rauf',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Method to show a dialog for importing book in project
  void showImportBookInProjectPopupDialog(
    BuildContext context,
    String projectName,
    HashMap<String, bool> booksMap,
    Future<bool> Function(List<String>) importBooksCallback,
  ) {
    List<String> books = booksMap.keys.toList();
    List<bool> alreadyImportedBooks = booksMap.values.toList();
    List<bool> selectedItems = List.generate(books.length, (index) => false);
    Set<String> selectedBooks = {};
    bool isBooksAvailable = books.isNotEmpty;
    bool showError = false;
    if (!isBooksAvailable) {
      showError = true;
    }
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4), // Blurred background
      builder: (BuildContext dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (MediaQuery.of(context).size.height < 650 ||
              MediaQuery.of(context).size.width < 1200) {
            if (Navigator.canPop(dialogContext)) {
              Navigator.pop(dialogContext);
            }
          }
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: StatefulBuilder(
            builder: (statefulBuilderContext, setState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (MediaQuery.of(context).size.height < 650) {
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                }
              });

              return Container(
                height: 600,
                width: 500,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),

                    // Title
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Import Book",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),

                    // Project Name
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                text: "Project Name: ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                children: [
                                  TextSpan(
                                    text: projectName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Books to import Display
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 10, bottom: 10, right: 20, top: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text("Importing Books: ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                )),
                          ),
                          Flexible(
                            child: SelectableText(
                              selectedBooks.isEmpty
                                  ? "None selected"
                                  : selectedBooks.join(", "),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.start,
                              cursorColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showError)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 7,
                          children: [
                            Icon(
                              Iconsax.danger5,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            Text(
                              isBooksAvailable
                                  ? "Select atleast one book to import!"
                                  : "No Books Available!",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // List of books with Checkboxes
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                isLoading // Check if loading, show progress indicator
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: books.length,
                                        itemBuilder: (context, index) {
                                          return Directionality(
                                            textDirection: TextDirection.rtl,
                                            child: CheckboxListTile(
                                              title: SelectableText(
                                                books[index].length >= 25
                                                    ? "${books[index].substring(0, 25)}..."
                                                    : books[index],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                textAlign: TextAlign.start,
                                                cursorColor: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              value: selectedItems[index] ||
                                                  alreadyImportedBooks[index],
                                              onChanged: alreadyImportedBooks[
                                                      index]
                                                  ? null
                                                  : (bool? value) {
                                                      setState(() {
                                                        selectedItems[index] =
                                                            value!;
                                                        if (value) {
                                                          showError = false;
                                                          selectedBooks.add(
                                                              books[index]);
                                                        } else {
                                                          selectedBooks.remove(
                                                              books[index]);
                                                        }
                                                      });
                                                    },
                                              checkboxScaleFactor: 0.7,
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ),
                      ),
                    ),

                    // Import Button
                    ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (selectedBooks.toList().isEmpty) {
                          setState(() => showError = true);
                        } else {
                          setState(() => isLoading = true);
                          var list = selectedBooks.toList();
                          bool success = await importBooksCallback(list);
                          setState(() => isLoading = false);
                          if (success) {
                            if (Navigator.canPop(dialogContext)) {
                              Navigator.pop(dialogContext);
                            }
                          } else {
                            setState(() => showError = true);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.import,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 11),
                              child: Text(
                                "Import",
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ]),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Method to show a dialog for importing book in project
  void showSaveQueryResultTypePopupDialog(
      BuildContext context,
      String projectName,
      List<String> books,
      Function(List<String>) importBooksCallback) {
    List<bool> selectedItems = List.generate(books.length, (index) => false);
    Set<String> selectedBooks = {};
    bool isBooksAvailable = books.isNotEmpty;
    bool showError = false;
    if (!isBooksAvailable) {
      showError = true;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4), // Blurred background
      builder: (BuildContext dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (MediaQuery.of(context).size.height < 650 ||
              MediaQuery.of(context).size.width < 1200) {
            if (Navigator.canPop(dialogContext)) {
              Navigator.pop(dialogContext);
            }
          }
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: StatefulBuilder(
            builder: (statefulBuilderContext, setState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (MediaQuery.of(context).size.height < 650) {
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.pop(dialogContext);
                  }
                }
              });

              return Container(
                height: 600,
                width: 500,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),

                    // Title
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Import Book",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),

                    // Project Name
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 10),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min, // Prevent unbounded width
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text.rich(TextSpan(
                              text: "Project Name: ",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              children: [
                                TextSpan(
                                    text: projectName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    )),
                              ])),
                        ],
                      ),
                    ),

                    // Books to import Display
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 10, bottom: 10, right: 20, top: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text("Importing Books: ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                )),
                          ),
                          Flexible(
                            child: SelectableText(
                              selectedBooks.isEmpty
                                  ? "None selected"
                                  : selectedBooks.join(", "),
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.start,
                              cursorColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showError)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: 7,
                          children: [
                            Icon(
                              Iconsax.danger5,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            Text(
                              isBooksAvailable
                                  ? "Select atleast one book to import!"
                                  : "No Books Available!",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // List of books with Checkboxes
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                return CheckboxListTile(
                                  title: SelectableText(
                                    books[index].length >= 25
                                        ? "${books[index].substring(0, 25)}..."
                                        : books[index],
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                    textAlign: TextAlign.start,
                                    cursorColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  value: selectedItems[index],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      selectedItems[index] = value!;
                                      if (value) {
                                        showError = false;
                                        selectedBooks.add(books[index]);
                                      } else {
                                        selectedBooks.remove(books[index]);
                                      }
                                    });
                                  },
                                  checkboxScaleFactor: 0.7,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Import Button
                    ElevatedButton(
                      onPressed: () {
                        if (selectedBooks.toList().isEmpty) {
                          setState(() => showError = true);
                        } else {
                          var list = selectedBooks.toList();
                          importBooksCallback(list);
                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.import,
                              size: 18,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 11),
                              child: Text(
                                "Import",
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ]),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
