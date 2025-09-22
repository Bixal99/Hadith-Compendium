import 'package:flutter/material.dart';
import 'package:hadith_iq/api/narrator_api.dart';
import 'package:hadith_iq/components/hover_icon_button.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:hadith_iq/components/my_tree_view.dart';
import 'package:hadith_iq/components/paginated_expansion_list.dart';
import 'package:hadith_iq/components/narrator_chains_widget.dart';
import 'package:hadith_iq/components/narrator_tree_widget.dart';
import 'package:iconsax/iconsax.dart';

class HadithNarratorDetailsPage extends StatefulWidget {
  final VoidCallback onBack;
  final String name;
  final String projectName;
  final bool isHadith;
  final String details;
  final List<String> sanad;
  final List<List<String>> narratedData;
  final List<List<String>> narratorTeachersStudents;

  const HadithNarratorDetailsPage(
      {super.key,
      required this.onBack,
      required this.name,
      required this.isHadith,
      required this.sanad,
      this.narratedData = const [[], []],
      this.narratorTeachersStudents = const [[], []],
      required this.projectName,
      required this.details});

  @override
  State<HadithNarratorDetailsPage> createState() =>
      _HadithNarratorDetailsPageState();
}

class _HadithNarratorDetailsPageState extends State<HadithNarratorDetailsPage> {
  final NarratorService _narratorService = NarratorService();

  @override
  Widget build(BuildContext context) {
    if (widget.isHadith && widget.sanad.isNotEmpty) {
      return FutureBuilder<Map<String, String>>(
        future:
            _fetchAllNarratorsAuthenticity(widget.projectName, widget.sanad),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          }

          final sanadDetails = snapshot.data!;

          return Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => _DetailsContent(
                key: widget.key,
                onBack: widget.onBack,
                name: widget.name,
                isHadith: widget.isHadith,
                details: widget.details,
                sanad: widget.sanad,
                narratedData: widget.narratedData,
                narratorTeachersStudents: widget.narratorTeachersStudents,
                projectName: widget.projectName,
                fetchNarratedHadiths: _fetchNarratedHadiths,
                fetchSimilarNarrators: _fetchSimilarNarrators,
                fetchNarratorDetails: _fetchNarratorDetails,
                fetchNarratorTeachersStudents: null,
                fetchAllNarratorsAuthenticity: _fetchAllNarratorsAuthenticity,
                narratorService: _narratorService,
                sanadDetails: sanadDetails,
              ),
            ),
          );
        },
      );
    }
    return Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => _DetailsContent(
          key: widget.key,
          onBack: widget.onBack,
          name: widget.name,
          isHadith: widget.isHadith,
          details: widget.details,
          sanad: widget.sanad,
          narratedData: widget.narratedData,
          projectName: widget.projectName,
          narratorTeachersStudents: widget.narratorTeachersStudents,
          fetchNarratedHadiths: _fetchNarratedHadiths,
          fetchSimilarNarrators: _fetchSimilarNarrators,
          fetchNarratorDetails: _fetchNarratorDetails,
          fetchNarratorTeachersStudents: _fetchNarratorTeachersStudents,
          fetchAllNarratorsAuthenticity: null,
          narratorService: _narratorService,
          sanadDetails: const {},
        ),
      ),
    );
  }

  Future<List<List<String>>> _fetchNarratedHadiths(
      String projectName, String narratorName) async {
    try {
      print(
          'Fetching narrator chains for: $narratorName in project: $projectName');

      // Use getNarratorChains instead since it contains the actual hadith texts
      dynamic response =
          await _narratorService.getNarratorChains('bilal', narratorName);

      print('API Response type: ${response.runtimeType}');
      print(
          'API Response: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');

      // Handle different response formats - API returns Map with 'chains' key
      List<dynamic> chains = [];

      if (response is Map<String, dynamic>) {
        // Response is a map, check for 'chains' key
        if (response.containsKey('chains')) {
          chains = response['chains'] as List<dynamic>? ?? [];
        }
        print('Found ${chains.length} chains from map response');
      } else if (response is List) {
        chains = response;
        print('Found ${chains.length} chains from direct list response');
      }

      if (chains.isNotEmpty) {
        // Extract hadith texts from chains data
        List<String> hadithTexts = chains
            .map<String>((chain) {
              if (chain is Map<String, dynamic>) {
                // Look for hadith text in the chain data
                String hadithText = chain['hadith_matn']?.toString() ??
                    chain['matn']?.toString() ??
                    chain['hadith_text']?.toString() ??
                    chain['text']?.toString() ??
                    chain['content']?.toString() ??
                    '';
                return hadithText;
              }
              return '';
            })
            .where((text) => text.isNotEmpty)
            .toList();

        // Extract sanad information from chains data
        List<String> sanadList = chains
            .map<String>((chain) {
              if (chain is Map<String, dynamic>) {
                final sanadText = chain['sanad_text'];
                if (sanadText is List) {
                  return sanadText
                      .map((e) => e.toString())
                      .toList()
                      .reversed
                      .join(' ← ');
                }
                if (sanadText is String) {
                  String cleaned = sanadText
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
            })
            .where((sanad) => sanad.isNotEmpty)
            .toList();

        print(
            'Successfully extracted ${hadithTexts.length} hadith texts and ${sanadList.length} sanads');
        return [hadithTexts, sanadList];
      } else {
        print(
            'No chains found in response - narrator may have no hadiths in this project');
        // Don't show error for empty results, just return empty data
        // The UI will handle showing "No narrated hadiths found!"
        return [];
      }
    } catch (e) {
      print('Error in _fetchNarratedHadiths: $e');

      // Only show error snackbar for actual connection/server errors, not empty results
      if (mounted && !e.toString().contains('No hadiths found')) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error connecting to server: Please check if backend is running',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }

      // Return test data to help debug the UI
      if (narratorName.contains('أبو هريرة') ||
          narratorName.contains('عمارة')) {
        print('Returning test data for debugging');
        return [
          [
            'حديث تجريبي الأول: قال رسول الله صلى الله عليه وسلم: إن الأعمال بالنيات وإنما لكل امرئ ما نوى',
            'حديث تجريبي الثاني: قال رسول الله صلى الله عليه وسلم: من حسن إسلام المرء تركه ما لا يعنيه',
            'حديث تجريبي الثالث: قال رسول الله صلى الله عليه وسلم: لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه',
          ],
          [
            'أبو هريرة ← عبد الرحمن بن عوف ← محمد بن إسحاق',
            'أبو هريرة ← سعد بن أبي وقاص ← الزهري',
            'أبو هريرة ← أنس بن مالك ← قتادة',
          ]
        ];
      }

      return [];
    }
  }

  Future<List<String>> _fetchSimilarNarrators(String narratorName) async {
    try {
      final List<String> results =
          await _narratorService.fetchSimilarNarrators(narratorName);
      return results;
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
            context,
            'Error fetching similar narratos: $e',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            true);
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
          'Error fetching narrator details: $e',
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

      // Check for error responses from backend
      if (teachers.isNotEmpty && teachers[0] == 'Error') {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            'Error fetching narrator teachers: ${teachers.length > 1 ? teachers[1] : "Backend error"}',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
        // Return empty list for teachers but still try students
        teachers = [];
      }

      if (students.isNotEmpty && students[0] == 'Error') {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            'Error fetching narrator students: ${students.length > 1 ? students[1] : "Backend error"}',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
        // Return empty list for students
        students = [];
      }

      // Check if data is empty (but no error)
      if (teachers.isEmpty && students.isEmpty) {
        if (mounted) {
          SnackBarCollection().primarySnackBar(
            context,
            'No teacher or student information available for this narrator in the database.',
            Icon(Iconsax.info_circle,
                color: Theme.of(context).colorScheme.onPrimary),
            false,
          );
        }
      } else if (teachers.isEmpty) {
        if (mounted) {
          SnackBarCollection().primarySnackBar(
            context,
            'No teacher information available for this narrator.',
            Icon(Iconsax.info_circle,
                color: Theme.of(context).colorScheme.onPrimary),
            false,
          );
        }
      } else if (students.isEmpty) {
        if (mounted) {
          SnackBarCollection().primarySnackBar(
            context,
            'No student information available for this narrator.',
            Icon(Iconsax.info_circle,
                color: Theme.of(context).colorScheme.onPrimary),
            false,
          );
        }
      }

      return [teachers, students];
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Network error fetching narrator teacher/student data: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
    return [[], []];
  }

  Future<Map<String, String>> _fetchAllNarratorsAuthenticity(
      String projectName, List<String> narratorNames) async {
    try {
      if (projectName.isEmpty) {
        return {};
      }
      final response = await _narratorService.getAllNarratorDetails(
        projectName,
        narratorNames,
      );

      final Map<String, String> result = {};

      for (final narrator in response) {
        final name = narrator['narrator_name'] ?? 'UNKNOWN';
        final opinion = narrator['final_opinion'] ?? 'NULL';
        result[name] = opinion;
      }

      return result;
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error fetching all narrator details: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
      return {};
    }
  }
}

class CustomLTRArrowPainter extends CustomPainter {
  final Color color;
  CustomLTRArrowPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Long horizontal tail (Right to Left)
    path.moveTo(70, 10); // Start from right
    path.lineTo(10, 10); // Draw to left

    // Small Arrowhead pointing left
    path.moveTo(10, 10);
    path.lineTo(15, 7); // Upper diagonal line
    path.moveTo(10, 10);
    path.lineTo(15, 13); // Lower diagonal line

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CustomTTBArrowPainter extends CustomPainter {
  final Color color;
  CustomTTBArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Long vertical tail (Top to Bottom)
    path.moveTo(10, 10);
    path.lineTo(10, 70); // Adjust length for a longer tail

    // Small Arrowhead pointing downward
    path.moveTo(10, 70);
    path.lineTo(7, 65); // Left diagonal line
    path.moveTo(10, 70);
    path.lineTo(13, 65); // Right diagonal line

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _DetailsContent extends StatefulWidget {
  final VoidCallback onBack;
  final String name;
  final String projectName;
  final bool isHadith;
  final String details;
  final List<String> sanad;
  final Map<String, String> sanadDetails;
  final List<List<String>> narratedData;
  final List<List<String>> narratorTeachersStudents;
  final Future<List<List<String>>> Function(String, String)
      fetchNarratedHadiths;
  final Future<List<String>> Function(String narratorName)
      fetchSimilarNarrators;
  final Future<String> Function(String projectName, String narratorName)
      fetchNarratorDetails;
  final Future<List<List<String>>> Function(String, String)?
      fetchNarratorTeachersStudents;
  final Future<Map<String, String>> Function(
          String projectName, List<String> narratorNames)?
      fetchAllNarratorsAuthenticity;
  final NarratorService narratorService;

  const _DetailsContent({
    super.key,
    required this.onBack,
    required this.name,
    required this.isHadith,
    required this.sanad,
    required this.narratedData,
    required this.projectName,
    required this.fetchNarratedHadiths,
    required this.narratorService,
    required this.details,
    required this.fetchSimilarNarrators,
    required this.fetchNarratorDetails,
    required this.sanadDetails,
    required this.fetchAllNarratorsAuthenticity,
    required this.narratorTeachersStudents,
    required this.fetchNarratorTeachersStudents,
  });

  @override
  State<_DetailsContent> createState() => __DetailsContentState();
}

class __DetailsContentState extends State<_DetailsContent> {
  final NarratorService _narratorService = NarratorService();
  late TreeNode treeNodeData;
  late TreeNode treeNodeDetails;
  bool isTreeDataEmpty = false;
  bool isHorizontal = true;
  List<bool> isGraphSelected = [
    true,
    false,
    false
  ]; // Added third option for chains
  List<String> similarNarratorsList = [];
  late ValueNotifier<TreeNode> treeNodeNotifier;
  Map<String, String> sanadDetails = {};
  final horizontalController = ScrollController();
  final verticalController = ScrollController();
  Map<String, dynamic>? narratorChainsData; // Store chains data

  // Dynamic data for narrated hadiths
  List<List<String>>? _dynamicNarratedData;
  bool _isLoadingNarratedData = false;
  bool _hasNarratedDataError = false;

  @override
  void initState() {
    super.initState();
    sanadDetails = Map<String, String>.from(widget.sanadDetails);
    isHorizontal = widget.isHadith ? true : false;
    _updateTreeData();
    treeNodeNotifier = ValueNotifier(treeNodeData);

    // For narrator details (not hadith), default to showing narrated hadiths tab
    if (!widget.isHadith) {
      isGraphSelected = [false, true, false]; // Select the narrated hadiths tab
    }

    // Automatically load narrated hadiths if no data is provided
    if (_shouldLoadNarratedData()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNarratedHadiths();
      });
    }
  }

  @override
  void dispose() {
    verticalController.dispose();
    horizontalController.dispose();
    super.dispose();
  }

  // Method to call the fetch and update the tree
  void _rebuildTreeData() async {
    final sanadDetailsRes = await widget.fetchAllNarratorsAuthenticity
        ?.call(widget.projectName, widget.sanad);

    final updatedSanadDetails = sanadDetailsRes ?? {};

    setState(() {
      sanadDetails.clear();
      sanadDetails.addAll(updatedSanadDetails);
      treeNodeData = _convertListToLinkedList(
        isHorizontal ? widget.sanad.toList() : widget.sanad.reversed.toList(),
        updatedSanadDetails,
      );
    });
    // Notify listeners for value change
    treeNodeNotifier.value = treeNodeData; // Trigger the rebuild
  }

  // Update the tree data with new details
  void _updateTreeData() {
    if (widget.isHadith) {
      setState(() {
        treeNodeData = _convertListToLinkedList(
            isHorizontal
                ? widget.sanad.toList()
                : widget.sanad.reversed.toList(),
            sanadDetails);
      });
    } else {
      List<String> teachers = widget.narratorTeachersStudents.isEmpty
          ? []
          : widget.narratorTeachersStudents[0];
      List<String> students = widget.narratorTeachersStudents.isEmpty
          ? []
          : widget.narratorTeachersStudents[1];
      treeNodeData = _convertListToTree(widget.name, teachers, students);
    }
  }

  TreeNode _convertListToLinkedList(
      List<String> names, Map<String, String> sanadDetails) {
    if (names.isEmpty) {
      isTreeDataEmpty = true;
      return TreeNode(value: 'Root');
    }

    Color getColorFromOpinion(String? opinion) {
      switch (opinion?.trim().toLowerCase()) {
        case 'positive':
          return const Color(0xFF1B4B29);
        case 'negative':
          return const Color(0xFF710E1A);
        case 'neutral':
          return const Color(0xFFD6C091);
        case 'not known':
          return const Color(0xFFDCC9A1);
        default:
          return Colors.grey; // fallback color
      }
    }

    TreeNode? current;
    for (String name in names.reversed) {
      final opinion = sanadDetails.isEmpty ? 'not known' : sanadDetails[name];
      final color = getColorFromOpinion(opinion);
      current = TreeNode(
          value: name,
          color: color,
          children: current == null ? [] : [current]);
    }
    return current!;
  }

  // Every item of list will be direct child of root node
  TreeNode _convertListToTree(
      String rootNodeValue, List<String> teachers, List<String> students) {
    if ((teachers.isEmpty && students.isEmpty) || rootNodeValue == '') {
      isTreeDataEmpty = true;
      return TreeNode(value: 'Root');
    }
    final List<TreeNode> children = [];

    // Add teachers (above the root)
    for (var teacher in teachers) {
      children.add(TreeNode(value: teacher, isAbove: true));
    }

    // Add students (below the root)
    for (var student in students) {
      children.add(TreeNode(value: student));
    }

    return TreeNode(
      value: rootNodeValue,
      children: children,
    );
  }

  void _associateNarratorWithDetailedNarrator(String projectName,
      String narratorName, String detailedNarratorName) async {
    try {
      final response = await widget.narratorService
          .associateNarratorWithDetailedNarrator(
              projectName, narratorName, detailedNarratorName);

      if (response['success'] == true) {
        if (mounted) {
          SnackBarCollection().successSnackBar(
              context,
              response['message'],
              Icon(Iconsax.tick_square,
                  color: Theme.of(context).colorScheme.onTertiary),
              true);
        }
        _rebuildTreeData();
      } else {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            "Association failed: ${response['message'] ?? 'Unknown error'}",
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          "Exception during association: $e",
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
  }

  void _updateAssociateNarratorWithDetailedNarrator(String projectName,
      String narratorName, String detailedNarratorName) async {
    try {
      final response = await widget.narratorService
          .updateAssociateNarratorWithDetailedNarrator(
              projectName, narratorName, detailedNarratorName);

      if (response['success'] == true) {
        if (mounted) {
          SnackBarCollection().successSnackBar(
              context,
              response['message'],
              Icon(Iconsax.tick_square,
                  color: Theme.of(context).colorScheme.onTertiary),
              true);
        }
        _rebuildTreeData();
      } else {
        if (mounted) {
          SnackBarCollection().errorSnackBar(
            context,
            "Association updation failed: ${response['message'] ?? 'Unknown error'}",
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          "Exception during association update: $e",
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
  }

  void _handleItemTap(String item) async {
    final newData = await widget.fetchNarratedHadiths(widget.projectName, item);
    final newDetails =
        await widget.fetchNarratorDetails(widget.projectName, item);
    final newNarratorTeachersStudents = await widget
        .fetchNarratorTeachersStudents
        ?.call(widget.projectName, item);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DetailsContent(
          key: ValueKey(item), // Use stable key based on content
          onBack: widget.onBack,
          name: item,
          isHadith: false,
          sanad: const [],
          details: newDetails,
          narratedData: newData,
          narratorTeachersStudents: newNarratorTeachersStudents ?? [[], []],
          projectName: widget.projectName,
          fetchNarratedHadiths: widget.fetchNarratedHadiths,
          fetchSimilarNarrators: widget.fetchSimilarNarrators,
          fetchNarratorDetails: widget.fetchNarratorDetails,
          fetchNarratorTeachersStudents: widget.fetchNarratorTeachersStudents,
          fetchAllNarratorsAuthenticity: null,
          narratorService: widget.narratorService, sanadDetails: const {},
        ),
      ),
    );
  }

  Future<bool> _handleItemRightClick(
      String item, List<String> similarNarratorsList) async {
    //'أَحْمَدُ'
    final narratorList = await widget.fetchSimilarNarrators(item);
    if (!mounted) return false;
    if (narratorList.isEmpty) {
      SnackBarCollection().errorSnackBar(
        context,
        'No similar Narrator found!',
        Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
        false,
      );
      return false;
    }
    similarNarratorsList.clear();
    similarNarratorsList.addAll(narratorList);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return _buildDetailsView(widget.name, widget.narratedData);
  }

  Widget _buildDetailsView(String name, List<List<String>> narratedData) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 30, bottom: 10, left: 25, right: 30),
            child: Row(
              children: [
                Tooltip(
                  message: "Back",
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 12),
                  waitDuration: const Duration(milliseconds: 300),
                  child: AnimatedHoverIconButton(
                    defaultIcon: Icons.arrow_circle_left_outlined,
                    hoverIcon: Icons.arrow_circle_left_rounded,
                    size: 20,
                    defaultColor: Theme.of(context).colorScheme.primary,
                    hoverColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      // Use the correct navigator state
                      final canPop =
                          Navigator.of(context, rootNavigator: false).canPop();
                      if (canPop) {
                        Navigator.of(context, rootNavigator: false).pop();
                      } else {
                        widget.onBack();
                      }
                    },
                    constraints: const BoxConstraints(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.isHadith ? 'Hadith Details' : 'Narrator Details',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 35, left: 35, top: 10, bottom: 20),
                    child: Row(
                      spacing: 20,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                            ),
                            alignment: Alignment.centerRight,
                            child: Column(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: widget.isHadith ? 5 : 2,
                                    TextSpan(
                                      text: widget.isHadith
                                          ? "حديث : "
                                          : "راوي : ",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: name,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ...!widget.isHadith
                            ? [
                                ToggleButtons(
                                  direction: Axis.vertical,
                                  onPressed: (int index) {
                                    setState(() {
                                      for (int i = 0;
                                          i < isGraphSelected.length;
                                          i++) {
                                        isGraphSelected[i] = i == index;
                                      }
                                      // Load chains data when chains tab is selected
                                      if (index == 2 &&
                                          narratorChainsData == null) {
                                        _loadNarratorChains();
                                      }
                                      // Load narrated hadiths when tab is selected and data is empty
                                      if (index == 1 &&
                                          _shouldLoadNarratedData()) {
                                        _loadNarratedHadiths();
                                      }
                                    });
                                  },
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(15)),
                                  selectedBorderColor:
                                      Theme.of(context).colorScheme.primary,
                                  borderColor:
                                      Theme.of(context).colorScheme.secondary,
                                  borderWidth: 0.5,
                                  selectedColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fillColor:
                                      Theme.of(context).colorScheme.primary,
                                  color: Theme.of(context).colorScheme.primary,
                                  constraints: const BoxConstraints(
                                      minHeight: 50, minWidth: 50),
                                  isSelected: isGraphSelected,
                                  children: [
                                    Tooltip(
                                        message: "Narrators Graph",
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        textStyle: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondary,
                                            fontSize: 12),
                                        waitDuration:
                                            const Duration(milliseconds: 300),
                                        child: const Icon(Iconsax.hierarchy,
                                            size: 22)),
                                    Tooltip(
                                        message: "Narrated Hadiths",
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        textStyle: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondary,
                                            fontSize: 12),
                                        waitDuration:
                                            const Duration(milliseconds: 300),
                                        child: const Icon(Iconsax.grid_7,
                                            size: 22)),
                                    Tooltip(
                                        message: "Narrator Chains",
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        textStyle: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondary,
                                            fontSize: 12),
                                        waitDuration:
                                            const Duration(milliseconds: 300),
                                        child: const Icon(Icons.link, size: 22))
                                  ],
                                ),
                              ]
                            : [],
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 0.5,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(15)),
                            ),
                            alignment: Alignment.centerRight,
                            child: widget.isHadith
                                ? Column(
                                    children: [
                                      Expanded(
                                        child: Text.rich(
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                          TextSpan(
                                            text: "كتب : ",
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: widget.details,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: Text.rich(
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          TextSpan(
                                            text: "اسم الراوي التفصيلي : ",
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: (!widget.isHadith &&
                                                        widget.details
                                                            .contains(' -- '))
                                                    ? () {
                                                        String detailedName =
                                                            widget.details
                                                                .split(
                                                                    ' -- ')[1]
                                                                .trim();
                                                        if (detailedName ==
                                                                'not known' ||
                                                            detailedName
                                                                .isEmpty ||
                                                            detailedName ==
                                                                '---' ||
                                                            detailedName ==
                                                                '--') {
                                                          return "غير متوفر"; // "Not available" in Arabic
                                                        }
                                                        return detailedName;
                                                      }()
                                                    : "غير متوفر", // "Not available" when no details
                                                style: TextStyle(
                                                  color: (!widget.isHadith &&
                                                          widget.details
                                                              .contains(' -- '))
                                                      ? () {
                                                          String detailedName =
                                                              widget.details
                                                                  .split(
                                                                      ' -- ')[1]
                                                                  .trim();
                                                          if (detailedName ==
                                                                  'not known' ||
                                                              detailedName
                                                                  .isEmpty ||
                                                              detailedName ==
                                                                  '---' ||
                                                              detailedName ==
                                                                  '--') {
                                                            return Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .outline; // Lighter color for "not available"
                                                          }
                                                          return Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurface;
                                                        }()
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .outline,
                                                  fontWeight: FontWeight.normal,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin:
                        const EdgeInsets.only(right: 35, left: 35, bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 0.5,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                    ),
                    child: Stack(
                      children: [
                        // Tree View or No Data Message
                        Positioned.fill(
                            child: isGraphSelected[0]
                                ? (!isTreeDataEmpty || !widget.isHadith)
                                    ? ValueListenableBuilder<TreeNode>(
                                        valueListenable: treeNodeNotifier,
                                        builder: (context, treeNodeData, _) {
                                          if (widget.isHadith) {
                                            return TreeViewWidget(
                                              key: ValueKey(treeNodeData),
                                              nodeData: treeNodeData,
                                              lineStyle: LineStyle.stepped,
                                              direction: isHorizontal
                                                  ? TreeDirection.horizontal
                                                  : TreeDirection.vertical,
                                              isNodeClickable: true,
                                              onNodeClick: (item) =>
                                                  _handleItemTap(item),
                                              onNodeRightClick: (item) =>
                                                  _handleItemRightClick(item,
                                                      similarNarratorsList),
                                              onListItemClick:
                                                  (listItem, nodeItemName) {
                                                if (sanadDetails[
                                                        nodeItemName] ==
                                                    "") {
                                                  _associateNarratorWithDetailedNarrator(
                                                    widget.projectName,
                                                    nodeItemName,
                                                    listItem,
                                                  );
                                                } else {
                                                  _updateAssociateNarratorWithDetailedNarrator(
                                                      widget.projectName,
                                                      nodeItemName,
                                                      listItem);
                                                }
                                              },
                                              itemsOnRightClick:
                                                  similarNarratorsList,
                                            );
                                          } else {
                                            // Use the new narrator tree widget for narrator details
                                            return NarratorTreeWidget(
                                              narratorName: widget.name,
                                              projectName: widget.projectName,
                                              onNarratorClick: (narratorName) {
                                                // Handle clicking on related narrators
                                                _handleItemTap(narratorName);
                                              },
                                            );
                                          }
                                        },
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.dnd_forwardslash_outlined,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              size: 60.0,
                                            ),
                                            const SizedBox(height: 15),
                                            Text(
                                              widget.isHadith
                                                  ? 'No Sanad Available!'
                                                  : 'No Narrator Tree Available!',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.0,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                : isGraphSelected[1]
                                    ? _buildNarratedHadithsView()
                                    : _buildChainsView()), // Third option for chains

                        // Arrow Icon Inside the Container (Top-Left)
                        if (!isTreeDataEmpty && isGraphSelected[0])
                          Positioned(
                              top: 7,
                              left: 7,
                              child: isHorizontal
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Direction",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 80,
                                          height: 15,
                                          child: CustomPaint(
                                            painter: CustomLTRArrowPainter(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          height: 12,
                                          child: CustomPaint(
                                            painter: CustomTTBArrowPainter(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                        RotatedBox(
                                          quarterTurns: 1,
                                          child: Text(
                                            "Direction",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainsView() {
    if (narratorChainsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return NarratorChainsWidget(
      chainsData: narratorChainsData!,
      narratorName: widget.name,
      onRefresh: _loadNarratorChains,
    );
  }

  void _loadNarratorChains() async {
    try {
      final chainsData = await _narratorService.getNarratorChains(
          widget.projectName, widget.name);
      setState(() {
        narratorChainsData = chainsData;
      });
    } catch (e) {
      // Handle error - could show snackbar or other user feedback
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error loading narrator chains: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
  }

  bool _shouldLoadNarratedData() {
    // Check if the passed narrated data is empty and we haven't loaded dynamic data yet
    return (widget.narratedData.isEmpty ||
            (widget.narratedData.length >= 2 &&
                widget.narratedData[0].isEmpty &&
                widget.narratedData[1].isEmpty)) &&
        _dynamicNarratedData == null &&
        !_isLoadingNarratedData;
  }

  void _loadNarratedHadiths() async {
    if (_isLoadingNarratedData) return;

    setState(() {
      _isLoadingNarratedData = true;
      _hasNarratedDataError = false; // Clear error flag when starting new load
    });

    try {
      print('Loading narrated hadiths for: ${widget.name} in project: bilal');

      // Use the same API call as _fetchNarratedHadiths for consistency
      dynamic response =
          await _narratorService.getNarratorChains('bilal', widget.name);

      print('API Response type: ${response.runtimeType}');
      print(
          'API Response: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');

      // Handle different response formats - API returns Map with 'chains' key
      List<dynamic> chains = [];

      if (response is Map<String, dynamic>) {
        // Response is a map, check for 'chains' key
        if (response.containsKey('chains')) {
          chains = response['chains'] as List<dynamic>? ?? [];
        }
        print('Found ${chains.length} chains from map response');
      } else if (response is List) {
        chains = response;
        print('Found ${chains.length} chains from direct list response');
      }

      List<String> hadiths = [];
      List<String> sanads = [];

      if (chains.isNotEmpty) {
        // Extract hadith texts from chains data
        List<String> hadithTexts = chains
            .map<String>((chain) {
              if (chain is Map<String, dynamic>) {
                // Look for hadith text in the chain data
                String hadithText = chain['hadith_matn']?.toString() ??
                    chain['matn']?.toString() ??
                    chain['hadith_text']?.toString() ??
                    chain['text']?.toString() ??
                    chain['content']?.toString() ??
                    '';
                return hadithText;
              }
              return '';
            })
            .where((text) => text.isNotEmpty)
            .toList();

        // Extract sanad information from chains data
        List<String> sanadList = chains
            .map<String>((chain) {
              if (chain is Map<String, dynamic>) {
                final sanadText = chain['sanad_text'];
                if (sanadText is List) {
                  return sanadText
                      .map((e) => e.toString())
                      .toList()
                      .reversed
                      .join(' ← ');
                }
                if (sanadText is String) {
                  String cleaned = sanadText
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
            })
            .where((sanad) => sanad.isNotEmpty)
            .toList();

        hadiths = hadithTexts;
        sanads = sanadList;
      }

      final narratedData = [hadiths, sanads];

      setState(() {
        _dynamicNarratedData = narratedData;
        _isLoadingNarratedData = false;
        _hasNarratedDataError = false; // Clear error flag on successful load
      });

      print('Successfully loaded ${hadiths.length} hadiths');
    } catch (e) {
      setState(() {
        _isLoadingNarratedData = false;
        _hasNarratedDataError = true; // Set error flag
      });
      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error loading narrated hadiths: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
  }

  // Get the effective narrated data (either passed data or dynamically loaded data)
  List<List<String>> _getEffectiveNarratedData() {
    if (_dynamicNarratedData != null) {
      return _dynamicNarratedData!;
    }
    return widget.narratedData;
  }

  Widget _buildNarratedHadithsView() {
    if (_isLoadingNarratedData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading narrated hadiths...'),
          ],
        ),
      );
    }

    final effectiveNarratedData = _getEffectiveNarratedData();

    if (effectiveNarratedData.isNotEmpty &&
        effectiveNarratedData.length >= 2 &&
        effectiveNarratedData[0].isNotEmpty) {
      return Row(
        children: [
          Expanded(
            child: PaginatedExpansionTileList(
              resultList: effectiveNarratedData[0],
              itemsPerPage: 35,
              isHadithDetails: false, // Set to false to hide Details button
              showItemSubHeadingInTile: effectiveNarratedData[1].isNotEmpty,
              subHeadingInTile: "سند : ",
              subHeadingTextListInTile: effectiveNarratedData[1],
              disableReload: true,
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _hasNarratedDataError
                  ? Icons.error_outline
                  : Icons.dnd_forwardslash_outlined,
              color: _hasNarratedDataError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
              size: 60.0,
            ),
            const SizedBox(height: 15),
            Text(
              _hasNarratedDataError
                  ? 'Error loading narrated hadiths'
                  : 'No narrated hadiths available for this narrator',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasNarratedDataError
                  ? 'There was a problem connecting to the server or processing the request.'
                  : 'This narrator does not have any recorded hadiths in the current project database.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => _loadNarratedHadiths(),
              child: Text(_hasNarratedDataError ? 'Retry Loading' : 'Refresh'),
            ),
          ],
        ),
      );
    }
  }
}
