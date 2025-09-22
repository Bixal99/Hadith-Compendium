import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadith_iq/api/narrator_api.dart';
import 'package:iconsax/iconsax.dart';

class ImportNarratorOverlay extends StatefulWidget {
  final String filePath;
  final String bookName;
  final VoidCallback onClose;
  const ImportNarratorOverlay(
      {super.key,
      required this.filePath,
      required this.bookName,
      required this.onClose});

  @override
  State<ImportNarratorOverlay> createState() => _ImportNarratorOverlayState();
}

class _ImportNarratorOverlayState extends State<ImportNarratorOverlay> {
  final NarratorService _narratorService = NarratorService();
  String narratorName = "";
  int currentStep = 0;
  List<bool> isLoading = List.generate(5, (index) => false);
  List<bool> isStopped = List.generate(5, (index) => false);
  List<bool> isStepChecked = List.generate(5, (index) => false);
  String errorMsg = '';
  int narratorCount = 0;
  List<String> narratedFromList = [];
  List<String> narratedToList = [];
  List<String> scholarNames = [];
  List<String> scholarOpinions = [];
  List<Map<String, String>> opinions = [];
  int? editingRow;
  int? editingColumn;
  TextEditingController controller = TextEditingController();
  TextEditingController narratorNumberController = TextEditingController();
  List<ScrollController> scrollControllersList =
      List.generate(4, (index) => ScrollController());
  ScrollController horizontalScrollController = ScrollController();
  final FocusNode narratorNumberFocus = FocusNode();
  bool showTick = false;
  bool isEnabled = false;
  String filePath = '';
  Completer<bool>? cleanTextCompleter;
  bool isTextCleaned = false;
  bool fetchingNarrators = false;

  // horizontalScrollController.animateTo(
  //     horizontalScrollController.position.maxScrollExtent,
  //     duration: Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );

  void changeFocus() {
    FocusScope.of(context).requestFocus(narratorNumberFocus);
  }

  @override
  void dispose() {
    narratorNumberController.dispose();
    narratorNumberFocus.dispose();
    horizontalScrollController.dispose();
    for (var controller in scrollControllersList) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    filePath = widget.filePath;
    Future.microtask(() => runPipeline());
    // Close the overlay if the screen size is small
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      if (screenSize.width < 1200 || screenSize.height < 650) {
        widget.onClose();
      }
    });
    narratorNumberFocus.addListener(() {
      if (narratorNumberFocus.hasFocus &&
          narratorNumberController.text.isNotEmpty) {
        setState(() => showTick = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;

      if (screenSize.width < 1200 || screenSize.height < 650) {
        widget.onClose();
      }
    });
  }

  void _submitField() {
    final value = narratorNumberController.text.trim();
    if (value.isNotEmpty) {
      final count = int.tryParse(value) ?? 0;
      narratorCount = count;
      cleanTextFile(count);
    }

    setState(() => showTick = false);
    narratorNumberFocus.unfocus(); // Hide keyboard
  }

  Future<void> runPipeline() async {
    if (await convertHtmlToTxt()) {
      cleanTextCompleter = Completer<bool>();
      bool isCleaned = await cleanTextCompleter!.future;

      if (isCleaned) {
        setState(() {
          isTextCleaned = isCleaned;
        });
        if (await fetchNarratorData(narratorCount)) {
          fetchingNarrators = true;
        }
      }
    }
  }

  Future<bool> convertHtmlToTxt() async {
    setState(() {
      isLoading[0] = true;
    });
    try {
      var response = await _narratorService.convertHtmlToText(filePath);
      if (response['status']) {
        setState(() {
          isLoading[0] = false;
          isStepChecked[0] = true;
          currentStep++;
          isEnabled = true;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            FocusScope.of(context).requestFocus(narratorNumberFocus);
          }
        });
        return true;
      } else {
        setState(() {
          isLoading[0] = false;
          isStopped[0] = true;
          errorMsg = response['message'];
        });
      }
    } on Exception catch (e) {
      setState(() {
        errorMsg = "Error in HTML to TXT conversion: $e";
      });
    }
    return false;
  }

  Future<bool> cleanTextFile(int count) async {
    if (count <= 0) {
      setState(() {
        errorMsg = "Number cannot be empty.";
      });
      cleanTextCompleter?.complete(false);
      return false;
    }
    setState(() {
      isLoading[1] = true;
      isEnabled = false;
    });
    try {
      var response = await _narratorService.cleanTextFile(filePath, count);
      if (response['status']) {
        setState(() {
          isLoading[1] = false;
          isStepChecked[1] = true;
          currentStep++;
        });
        cleanTextCompleter?.complete(true);
        return true;
      } else {
        setState(() {
          isLoading[1] = false;
          isStopped[1] = true;
          errorMsg = response['message'];
        });
      }
    } on Exception catch (e) {
      setState(() {
        errorMsg = "Error in TXT cleaning: $e";
      });
    }
    cleanTextCompleter?.complete(false);
    return false;
  }

  Future<bool> fetchNarratorData(int count) async {
    if (count <= 0) {
      setState(() {
        errorMsg = "Number cannot be empty.";
      });
      return false;
    }
    setState(() {
      isLoading[2] = true;
      isStepChecked[2] = false;
    });
    try {
      var response = await _narratorService.fetchNarratorData(filePath, count);
      if (isValidResponse(response)) {
        setState(() {
          isLoading[2] = false;
          isStepChecked[2] = true;
          if (currentStep == 2) {
            currentStep++;
          }
        });
        extractNarratorDetails(response);
        return true;
      } else {
        setState(() {
          isLoading[2] = false;
          isStopped[2] = true;
          errorMsg = "Error in Fetching narrators API call.";
        });
      }
    } on Exception catch (e) {
      setState(() {
        errorMsg = "Error in Fetching Narrator Details : $e";
      });
    }
    return false;
  }

  Future<bool> importNarratorData(
      String narratorName,
      List<String> narratorTeacher,
      List<String> narratorStudent,
      List<String> opinion,
      List<String> scholar) async {
    setState(() {
      isLoading[3] = true;
      isStepChecked[3] = false;
    });
    try {
      var response = await _narratorService.importNarrator(
          narratorName, narratorTeacher, narratorStudent, opinion, scholar);
      if (response['success']) {
        setState(() {
          isLoading[3] = false;
          isStepChecked[3] = true;
          if (currentStep == 3) {
            currentStep++;
          }
        });
        return true;
      } else {
        setState(() {
          isLoading[3] = false;
          isStopped[3] = true;
          errorMsg = "Error in saving the result.";
        });
      }
    } on Exception catch (e) {
      setState(() {
        errorMsg = "Error in Saving Narrator Details : $e";
      });
    }
    return false;
  }

  bool isValidResponse(Map<String, dynamic> response) {
    if (response.isEmpty || response['response'] == null) return false;

    var res1 = response['response']['response_1'];
    var res2 = response['response']['response_2'];

    if (res1 == null || res2 == null) return false;

    if (res1['narrator_name'] == null ||
        res1['learned_from'] == null ||
        res1['learned_to'] == null) {
      return false;
    }

    if (res2['narrator_name'] == null || res2['opinions'] == null) {
      return false;
    }

    return true;
  }

  void extractNarratorDetails(Map<String, dynamic> response) {
    var response1 = response['response']['response_1'];
    var response2 = response['response']['response_2'];

    setState(() {
      narratorName = response1['narrator_name'];
    });

    var learnedFromRaw = response1['learned_from'];

    if (learnedFromRaw is Iterable) {
      narratedFromList = List<String>.from(learnedFromRaw);
    } else if (learnedFromRaw is String) {
      narratedFromList = [learnedFromRaw];
    } else {
      narratedFromList = [];
    }
    var learnedToRaw = response1['learned_to'];

    if (learnedToRaw is Iterable) {
      narratedToList = List<String>.from(learnedToRaw);
    } else if (learnedToRaw is String) {
      narratedToList = [learnedToRaw];
    } else {
      narratedToList = [];
    }
    // narratedToList = List<String>.from(response1['learned_to'] ?? []);

    setState(() {
      scholarNames.clear();
      scholarOpinions.clear();

      response2['opinions'].forEach((op) {
        scholarNames.add(op["scholar_name"].toString());
        scholarOpinions.add(op["opinion"].toString());
      });
    });
  }

  Widget buildEditableListColumn({
    required String title,
    required List<String> list,
    required ScrollController scrollController,
    required int columnIndex,
    required void Function(int rowIndex) onEdit,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: 350,
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Expanded(
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  itemBuilder: (context, rowIndex) {
                    return GestureDetector(
                      onDoubleTap: () {
                        setState(() {
                          editingRow = rowIndex;
                          editingColumn = columnIndex;
                          controller.text = list[rowIndex];
                        });
                      },
                      child: ListTile(
                        title: editingRow == rowIndex &&
                                editingColumn == columnIndex
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      autofocus: true,
                                      onSubmitted: (newValue) {
                                        setState(() {
                                          list[rowIndex] = newValue;
                                          editingRow = null;
                                          editingColumn = null;
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.check,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    onPressed: () {
                                      setState(() {
                                        list[rowIndex] = controller.text;
                                        editingRow = null;
                                        editingColumn = null;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      list[rowIndex],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        editingRow = rowIndex;
                                        editingColumn = columnIndex;
                                        controller.text = list[rowIndex];
                                      });
                                    },
                                    icon: Icon(Icons.edit,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        Material(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          color: Theme.of(context).colorScheme.surface,
          child: Container(
            height: 670,
            width: 750,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: widget.onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),

                // Title
                Text(
                  "Import Narrator Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    // Wrap with Row to allow Expanded
                    children: [
                      Text(
                        "Narrator: ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Expanded(
                        // Prevents overflow
                        child: Text(
                          narratorName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bookname
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [
                          SizedBox(
                              width: 210,
                              height: 35,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: narratorNumberController,
                                      focusNode: narratorNumberFocus,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        labelText: "Narrator Number",
                                        labelStyle: TextStyle(fontSize: 12),
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 8),
                                        hintText: "Enter number",
                                        hintStyle: TextStyle(fontSize: 12),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(5),
                                        FilteringTextInputFormatter.digitsOnly,
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'^[1-9][0-9]{0,4}$')),
                                      ],
                                      enabled: isEnabled,
                                      onSubmitted: (value) => _submitField(),
                                      onChanged: (value) {
                                        if (narratorNumberController
                                            .text.isNotEmpty) {
                                          setState(() => showTick = true);
                                        } else {
                                          setState(() => showTick = false);
                                        }
                                      },
                                    ),
                                  ),
                                  if (showTick)
                                    Tooltip(
                                      message: "Submit",
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondary,
                                          fontSize: 12),
                                      waitDuration:
                                          const Duration(milliseconds: 300),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IconButton(
                                          icon: Icon(Icons.check,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary),
                                          onPressed: _submitField,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  if (isStepChecked[2] || isStopped[2])
                                    Tooltip(
                                      message: "Retry",
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      textStyle: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondary,
                                          fontSize: 12),
                                      waitDuration:
                                          const Duration(milliseconds: 300),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: IconButton(
                                          icon: Icon(Iconsax.refresh,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                          onPressed: () async {
                                            setState(() {
                                              errorMsg = '';
                                              isStopped[2] =
                                                  isStopped[3] = false;
                                            });
                                            if (await fetchNarratorData(
                                                narratorCount)) {
                                              fetchingNarrators = true;
                                            }
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                ],
                              )),
                          Text(
                            "Number of first narrator in HTML file.",
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest),
                          ),
                        ],
                      )),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 35, right: 30),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            "Converting\nto.txt file",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Removing\nextra text",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Fetching each\nNarrator details",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Saving\nto database",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Saved\nsuccessfully",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                  ),
                ),

                // Progress Display
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        bool isCircleActive = index < currentStep;
                        bool isLineActive = index < currentStep - 1;
                        if (isCircleActive) {
                          isStepChecked[index] = true;
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Circular Point (Animated when loading)
                            isLoading[index]
                                ? Padding(
                                    padding: const EdgeInsets.all(
                                        4.0), // Padding only for loading icon
                                    child: SizedBox(
                                      width: 16, // Smaller size
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isCircleActive
                                        ? Icons.check_circle
                                        : isStopped[index]
                                            ? Icons.cancel_rounded
                                            : Icons.circle_outlined,
                                    size: 20,
                                    color: isCircleActive
                                        ? Theme.of(context).colorScheme.tertiary
                                        : isStopped[index]
                                            ? Theme.of(context)
                                                .colorScheme
                                                .error
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                  ),

                            // Line between circles (only for first 4)
                            if (index < 4)
                              Container(
                                width: 100,
                                height: 2,
                                color: isLineActive
                                    ? Theme.of(context).colorScheme.tertiary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                if (errorMsg.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, bottom: 10, right: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 7,
                      children: [
                        Icon(
                          Iconsax.danger5,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        Expanded(
                          child: Text(
                            "Error : $errorMsg",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                // List of Queries with edit
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        controller: horizontalScrollController,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: horizontalScrollController,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // First List (Column 1)
                              buildEditableListColumn(
                                title: "Narrated From",
                                list: narratedFromList,
                                scrollController: scrollControllersList[0],
                                columnIndex: 0,
                                onEdit: (index) {
                                  controller.text = narratedFromList[index];
                                },
                              ),

                              VerticalDivider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                thickness: 0.5,
                                indent: 50,
                                endIndent: 60,
                              ),

                              // Second List (Column 2)
                              buildEditableListColumn(
                                title: "Narrated To",
                                list: narratedToList,
                                scrollController: scrollControllersList[1],
                                columnIndex: 1,
                                onEdit: (index) {
                                  controller.text = narratedToList[index];
                                },
                              ),

                              VerticalDivider(
                                color: Theme.of(context).colorScheme.secondary,
                                thickness: 1,
                              ),

                              // Third List (Column 3)
                              buildEditableListColumn(
                                title: "Scholars",
                                list: scholarNames,
                                scrollController: scrollControllersList[2],
                                columnIndex: 2,
                                onEdit: (index) {
                                  controller.text = scholarNames[index];
                                },
                              ),

                              VerticalDivider(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                thickness: 0.5,
                                indent: 50,
                                endIndent: 60,
                              ),

                              // Fourth List (Column 4)
                              buildEditableListColumn(
                                title: "Opinions",
                                list: scholarOpinions,
                                scrollController: scrollControllersList[3],
                                columnIndex: 3,
                                onEdit: (index) {
                                  controller.text = scholarOpinions[index];
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Row(
                  spacing: 7,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: ElevatedButton(
                          onPressed: (isStepChecked.length > 4 &&
                                  isStepChecked[2] &&
                                  (!isLoading[2]))
                              ? isStepChecked[3]
                                  ? null
                                  : () {
                                      importNarratorData(
                                          narratorName,
                                          narratedFromList,
                                          narratedToList,
                                          scholarOpinions,
                                          scholarNames);
                                    }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                                  Iconsax.import_2,
                                  size: 22,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 11),
                                  child: Text(
                                    "Save",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              ]),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ElevatedButton(
                          onPressed: (isStepChecked.length > 4 &&
                                  isStepChecked[2] &&
                                  (!isLoading[2]))
                              ? () {
                                  if (currentStep == 4) {
                                    currentStep -= 2;
                                  }
                                  setState(() {
                                    isLoading[3] = false;
                                    isStepChecked[3] = false;
                                  });
                                  if (isTextCleaned && fetchingNarrators) {
                                    fetchNarratorData(++narratorCount);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                                  Icons.next_plan_outlined,
                                  size: 22,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 11),
                                  child: Text(
                                    "Next",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
