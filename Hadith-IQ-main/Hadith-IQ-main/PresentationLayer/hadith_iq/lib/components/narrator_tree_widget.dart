import 'package:flutter/material.dart';
import 'package:hadith_iq/api/narrator_api.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:iconsax/iconsax.dart';

class NarratorTreeWidget extends StatefulWidget {
  final String narratorName;
  final String projectName;
  final Function(String)? onNarratorClick;
  final List<String> navigationPath; // Track the navigation path

  const NarratorTreeWidget({
    super.key,
    required this.narratorName,
    required this.projectName,
    this.onNarratorClick,
    this.navigationPath = const [], // Default to empty path
  });

  @override
  State<NarratorTreeWidget> createState() => _NarratorTreeWidgetState();
}

class _NarratorTreeWidgetState extends State<NarratorTreeWidget> {
  final NarratorService _narratorService = NarratorService();
  Map<String, dynamic>? _treeData;
  bool _isLoading = false;
  String? _errorMessage;

  // Current narrator for navigation
  late String _currentNarrator;
  
  // Zoom level for the tree
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _currentNarrator = widget.narratorName;
    _loadNarratorTree();
  }

  void _navigateToNarrator(String narratorName) {
    print('Opening new page for narrator: $narratorName');

    // Create new path by adding current narrator to existing path
    final newPath = [...widget.navigationPath, _currentNarrator];

    // Instead of updating current page, navigate to new page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Narrator Tree - $narratorName'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: NarratorTreeWidget(
            narratorName: narratorName,
            projectName: widget.projectName,
            onNarratorClick: widget.onNarratorClick,
            navigationPath: newPath, // Pass the updated path
          ),
        ),
      ),
    );
  }

  Future<void> _loadNarratorTree() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get narrator chains data for building the tree structure
      final chainsResponse = await _narratorService.getNarratorChains(
        widget.projectName,
        _currentNarrator,
      );

      // Get narrator tree data (teachers and students)
      final treeResponse = await _narratorService.getNarratorTree(
        widget.projectName,
        _currentNarrator,
      );

      // Process and structure the tree data based on isnad chains
      final structuredTree = _processIsnadChains(chainsResponse, treeResponse);

      setState(() {
        _treeData = structuredTree;
        _isLoading = false;
      });

      print('Loaded tree for $_currentNarrator:');
      print('Teacher: ${structuredTree['direct_teacher']}');
      print(
          'Current: ${structuredTree['narrator']?['name'] ?? _currentNarrator}');
      print('Student: ${structuredTree['direct_student']}');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        SnackBarCollection().errorSnackBar(
          context,
          'Error loading narrator tree: $e',
          Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
          false,
        );
      }
    }
  }

  /// Process isnad chains to find direct teacher and student relationships
  Map<String, dynamic> _processIsnadChains(
      dynamic chainsData, Map<String, dynamic> treeData) {
    print('Chain data received: $chainsData');

    if (chainsData == null) {
      print('Chain data is null');
      return treeData;
    }

    // Handle different possible response formats
    List<dynamic> chains = [];
    if (chainsData is Map<String, dynamic> && chainsData['chains'] != null) {
      chains = chainsData['chains'] as List<dynamic>;
    } else if (chainsData is List<dynamic>) {
      chains = chainsData;
    } else {
      print('Unexpected chain data format: ${chainsData.runtimeType}');
      return treeData;
    }

    print('Processing ${chains.length} chains');

    String? directTeacher;
    String? directStudent;

    // Find the most common direct teacher and student from chains
    Map<String, int> teacherFrequency = {};
    Map<String, int> studentFrequency = {};

    // Process each chain to find direct relationships
    for (var chain in chains) {
      if (chain == null || chain['chain_structure'] == null) continue;

      List<dynamic> chainStructure = chain['chain_structure'] as List<dynamic>;
      print(
          'Chain structure for chain ${chain['sanad_id']}: ${chainStructure.length} narrators');

      // Sort by level to ensure proper ordering (level 1 is closest to Prophet)
      chainStructure.sort((a, b) => a['level'].compareTo(b['level']));

      int targetIndex = -1;
      // Find the target narrator in the chain
      for (int i = 0; i < chainStructure.length; i++) {
        String narratorName =
            chainStructure[i]['narrator_name']?.toString() ?? '';
        bool isTarget = chainStructure[i]['is_target'] == true;

        // Also check if narrator name matches (case insensitive and trim whitespace)
        String cleanNarratorName = narratorName.trim().toLowerCase();
        String cleanTargetName = _currentNarrator.trim().toLowerCase();

        if (isTarget ||
            cleanNarratorName == cleanTargetName ||
            cleanNarratorName.contains(cleanTargetName) ||
            cleanTargetName.contains(cleanNarratorName)) {
          targetIndex = i;
          print(
              'Found target narrator at index $i: $narratorName (isTarget: $isTarget)');
          break;
        }
      }

      if (targetIndex != -1) {
        // Direct teacher is the narrator immediately before (lower level number)
        if (targetIndex > 0) {
          String teacherName =
              chainStructure[targetIndex - 1]['narrator_name']?.toString() ??
                  '';
          if (teacherName.isNotEmpty &&
              teacherName.trim() != _currentNarrator.trim()) {
            teacherFrequency[teacherName] =
                (teacherFrequency[teacherName] ?? 0) + 1;
            print(
                'Found teacher: $teacherName (frequency: ${teacherFrequency[teacherName]})');
          }
        }

        // Direct student is the narrator immediately after (higher level number)
        if (targetIndex < chainStructure.length - 1) {
          String studentName =
              chainStructure[targetIndex + 1]['narrator_name']?.toString() ??
                  '';
          if (studentName.isNotEmpty &&
              studentName.trim() != _currentNarrator.trim()) {
            studentFrequency[studentName] =
                (studentFrequency[studentName] ?? 0) + 1;
            print(
                'Found student: $studentName (frequency: ${studentFrequency[studentName]})');
          }
        }
      } else {
        print('Target narrator not found in this chain');
      }
    }

    print('Teacher frequencies: $teacherFrequency');
    print('Student frequencies: $studentFrequency');

    // Select most frequent direct teacher and student
    if (teacherFrequency.isNotEmpty) {
      directTeacher = teacherFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      print('Selected direct teacher: $directTeacher');
    }

    if (studentFrequency.isNotEmpty) {
      directStudent = studentFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      print('Selected direct student: $directStudent');
    }

    // Fallback to tree data if chain processing didn't find relationships
    if (directTeacher == null && directStudent == null) {
      // Try to get data from the tree response as fallback
      var teachers = treeData['teachers'] as List<dynamic>?;
      var students = treeData['students'] as List<dynamic>?;

      if (teachers != null && teachers.isNotEmpty) {
        directTeacher = teachers.first.toString();
        print('Fallback teacher from tree data: $directTeacher');
      }

      if (students != null && students.isNotEmpty) {
        directStudent = students.first.toString();
        print('Fallback student from tree data: $directStudent');
      }
    }

    // Build the linear tree structure with all teachers and students
    return {
      'narrator': treeData['narrator'] ?? {'name': _currentNarrator},
      'direct_teacher': directTeacher,
      'direct_student': directStudent,
      'all_teachers': teacherFrequency.keys.toList(),
      'all_students': studentFrequency.keys.toList(),
      'chains_data': chainsData,
      'total_chains': chains.length,
      'teacher_frequency': teacherFrequency,
      'student_frequency': studentFrequency,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading narrator tree...'),
          ],
        ),
      );
    }

    if (_errorMessage != null || _treeData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load narrator tree',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNarratorTree,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Navigation controls
              _buildNavigationControls(),
              const SizedBox(height: 16),

              // Tree visualization with zoom
              Transform.scale(
                scale: _zoomLevel,
                child: _buildTreeVisualization(),
              ),
            ],
          ),
        ),
        
        // Zoom controls positioned at bottom right
        Positioned(
          bottom: 20,
          right: 20,
          child: _buildZoomControls(),
        ),
      ],
    );
  }

  Widget _buildTreeVisualization() {
    final allTeachers = _treeData!['all_teachers'] as List<dynamic>? ?? [];
    final allStudents = _treeData!['all_students'] as List<dynamic>? ?? [];
    final narrator = _treeData!['narrator'] as Map<String, dynamic>;
    final totalChains = _treeData!['total_chains'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Vertical chain: Teachers -> Narrator -> Students
            _buildVerticalChainWithAll(allTeachers, narrator, allStudents),

            // Empty state message - show only if no chains at all
            if (totalChains == 0)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.link_off,
                      color: Theme.of(context).colorScheme.outline,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد سلاسل إسناد لهذا الراوي',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No isnad chains found for this narrator',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalChainWithAll(List<dynamic> allTeachers,
      Map<String, dynamic> narrator, List<dynamic> allStudents) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // All Teachers (Top) - Horizontal Row with Arrows
          if (allTeachers.isNotEmpty) ...[
            _buildNarratorsWithArrows(
              narrators: allTeachers.cast<String>(),
              isTeachers: true,
            ),
          ],

          // No teachers message
          if (allTeachers.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا يوجد أساتذة',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'No teachers found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Current Narrator (Center) - No spacing, directly connected
          Center(
            child: _buildChainNode(
              name: narrator['name'] ?? _currentNarrator,
              icon: Icons.person,
              isClickable: false,
              isCenter: true,
            ),
          ),

          // All Students (Bottom) - Horizontal Row with Arrows
          if (allStudents.isNotEmpty) ...[
            _buildNarratorsWithArrows(
              narrators: allStudents.cast<String>(),
              isTeachers: false,
            ),
          ],

          // No students message
          if (allStudents.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا يوجد تلاميذ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'No students found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // No relationships found message
          if (allTeachers.isEmpty && allStudents.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'هذا الراوي ليس له أستاذ أو تلميذ مباشر في السلاسل المتاحة',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This narrator has no direct teacher or student in available chains',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNarratorsWithArrows({
    required List<String> narrators,
    required bool isTeachers,
  }) {
    // Calculate center position for each narrator box
    // Each box has: minWidth: 120, maxWidth: 200, margin: 50 on each side
    // Average box width ~160, total width per box = 160 + 100(margins) = 260
    const double approximateBoxWidth = 260.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // For teachers: boxes first, then arrows below them pointing down to center
        // For students: arrows first from center pointing down to boxes, then boxes
        if (isTeachers) ...[
          // Teacher boxes at top
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: narrators.map((narrator) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                child: _buildChainNode(
                  name: narrator,
                  icon: Icons.school,
                  isClickable: true,
                  isCenter: false,
                ),
              );
            }).toList(),
          ),
          // Individual arrows from each teacher box converging to center - more space
          SizedBox(
            height: 500,
            width: narrators.length * approximateBoxWidth,
            child: CustomPaint(
              painter: ConnectedArrowsPainter(
                count: narrators.length,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                isDownward: true,
                boxSpacing: approximateBoxWidth,
              ),
              child: Container(),
            ),
          ),
        ] else ...[
          // Individual arrows from center diverging to each student box - more space
          SizedBox(
            height: 500,
            width: narrators.length * approximateBoxWidth,
            child: CustomPaint(
              painter: ConnectedArrowsFromCenterPainter(
                count: narrators.length,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                boxSpacing: approximateBoxWidth,
              ),
              child: Container(),
            ),
          ),
          // Student boxes at bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: narrators.map((narrator) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                child: _buildChainNode(
                  name: narrator,
                  icon: Icons.person_outline,
                  isClickable: true,
                  isCenter: false,
                ),
              );
            }).toList(),
          ),
          // Extra space at bottom to make arrowheads visible
          const SizedBox(height: 60),
        ],
      ],
    );
  }

  Widget _buildHorizontalScrollableRow({
    required List<String> narrators,
    required bool isTeachers,
  }) {
    return Center(
      child: SizedBox(
        height: 100,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: narrators.asMap().entries.map((entry) {
              final narrator = entry.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 50),
                child: _buildChainNode(
                  name: narrator,
                  icon: isTeachers ? Icons.school : Icons.person_outline,
                  isClickable: true,
                  isCenter: false,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChainNode({
    required String name,
    required IconData icon,
    bool isClickable = true,
    bool isCenter = false,
  }) {
    // Use colored styling for center node, gray for others
    final nodeColor =
        isCenter ? Theme.of(context).colorScheme.primary : Colors.grey.shade600;

    final baseContainer = Container(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 200,
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: nodeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: nodeColor.withOpacity(0.6),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: nodeColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: nodeColor,
                  fontSize: 16,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (isClickable) {
      return InkWell(
        onTap: () => _navigateToNarrator(name),
        borderRadius: BorderRadius.circular(18),
        child: baseContainer,
      );
    }

    return baseContainer;
  }

  Widget _buildMultipleConnectors(int count, {required bool isDownward}) {
    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: MultipleArrowsPainter(
          count: count,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          isDownward: isDownward,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildVerticalConnector({required bool isDownward}) {
    return Container(
      width: 3,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisAlignment:
            isDownward ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            width: 0,
            height: 0,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 6,
                  color: Colors.transparent,
                ),
                right: BorderSide(
                  width: 6,
                  color: Colors.transparent,
                ),
                top: BorderSide(
                  width: isDownward ? 0 : 10,
                  color: isDownward
                      ? Colors.transparent
                      : Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
                bottom: BorderSide(
                  width: isDownward ? 10 : 0,
                  color: isDownward
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation controls header
          Row(
            children: [
              const SizedBox(width: 48), // Placeholder for alignment

              // Page title
              Expanded(
                child: Center(
                  child: Text(
                    'Narrator Tree',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),

              // Reset to original narrator button
              if (_currentNarrator != widget.narratorName)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentNarrator = widget.narratorName;
                    });
                    _loadNarratorTree();
                  },
                  icon: Icon(
                    Icons.home,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  tooltip: 'Return to ${widget.narratorName}',
                )
              else
                const SizedBox(width: 48), // Placeholder for alignment
            ],
          ),

          // Navigation path breadcrumb
          if (widget.navigationPath.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Icon(
                      Icons.route,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Path: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                          ),
                    ),
                    ...List.generate(widget.navigationPath.length, (index) {
                      return Row(
                        children: [
                          Text(
                            widget.navigationPath[index],
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ],
                      );
                    }),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentNarrator,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom In button
          IconButton(
            onPressed: () {
              setState(() {
                if (_zoomLevel < 2.0) {
                  _zoomLevel += 0.1;
                }
              });
            },
            icon: const Icon(Icons.add),
            tooltip: 'Zoom In',
            color: Theme.of(context).colorScheme.primary,
          ),
          
          // Zoom level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          
          // Zoom Out button
          IconButton(
            onPressed: () {
              setState(() {
                if (_zoomLevel > 0.5) {
                  _zoomLevel -= 0.1;
                }
              });
            },
            icon: const Icon(Icons.remove),
            tooltip: 'Zoom Out',
            color: Theme.of(context).colorScheme.primary,
          ),
          
          // Reset zoom button
          IconButton(
            onPressed: () {
              setState(() {
                _zoomLevel = 1.0;
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Zoom',
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class IsnadTreeLinePainter extends CustomPainter {
  final Color color;
  final bool isDownward;

  IsnadTreeLinePainter({required this.color, required this.isDownward});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final startY = isDownward ? 0.0 : size.height;
    final endY = isDownward ? size.height : 0.0;

    // Draw main vertical line
    canvas.drawLine(
      Offset(centerX, startY),
      Offset(centerX, endY),
      paint,
    );

    // Draw multiple branching lines for tree effect
    final branchY = isDownward ? size.height * 0.7 : size.height * 0.3;
    final branchWidth = size.width * 0.3;

    // Left branch
    canvas.drawLine(
      Offset(centerX, branchY),
      Offset(centerX - branchWidth, branchY),
      paint,
    );

    // Right branch
    canvas.drawLine(
      Offset(centerX, branchY),
      Offset(centerX + branchWidth, branchY),
      paint,
    );

    // Draw arrow indicating direction
    final arrowPath = Path();
    final arrowSize = 8.0;
    if (isDownward) {
      arrowPath.moveTo(centerX - arrowSize, size.height - arrowSize);
      arrowPath.lineTo(centerX, size.height);
      arrowPath.lineTo(centerX + arrowSize, size.height - arrowSize);
    } else {
      arrowPath.moveTo(centerX - arrowSize, arrowSize);
      arrowPath.lineTo(centerX, 0);
      arrowPath.lineTo(centerX + arrowSize, arrowSize);
    }

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectedArrowsPainter extends CustomPainter {
  final int count;
  final Color color;
  final bool isDownward;
  final double boxSpacing;

  ConnectedArrowsPainter({
    required this.count,
    required this.color,
    required this.isDownward,
    required this.boxSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    // Calculate exact positions - boxes have 100px margin between them (50px each side)
    // So actual spacing between box centers is boxSpacing
    final totalWidth = (count - 1) * boxSpacing;
    final startX = centerX - (totalWidth / 2);

    // Draw individual arrows - each from its box CENTER to center narrator
    for (int i = 0; i < count; i++) {
      // Calculate the center of each box
      final boxCenterX = startX + (i * boxSpacing);

      // Draw line from each box's center position
      final path = Path();

      // Start from top at box center exactly at box edge (no gap)
      path.moveTo(boxCenterX, 0); // Start at 0 to touch box bottom

      // Draw curved line to center narrator
      path.quadraticBezierTo(
        boxCenterX,
        size.height * 0.3, // Control point for curve
        centerX,
        size.height, // End at bottom to touch box top
      );

      canvas.drawPath(path, paint);

      // Draw arrowhead at the bottom pointing to center
      final arrowPath = Path();
      final arrowSize = 6.0;

      arrowPath.moveTo(centerX - arrowSize, size.height - arrowSize);
      arrowPath.lineTo(centerX, size.height);
      arrowPath.lineTo(centerX + arrowSize, size.height - arrowSize);

      canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectedArrowsFromCenterPainter extends CustomPainter {
  final int count;
  final Color color;
  final double boxSpacing;

  ConnectedArrowsFromCenterPainter({
    required this.count,
    required this.color,
    required this.boxSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    // Calculate exact positions - boxes have 100px margin between them (50px each side)
    final totalWidth = (count - 1) * boxSpacing;
    final startX = centerX - (totalWidth / 2);

    // Draw individual arrows from center to each student box CENTER
    for (int i = 0; i < count; i++) {
      // Calculate the center of each box
      final boxCenterX = startX + (i * boxSpacing);

      // Draw line from center to each box's center position
      final path = Path();

      // Start from center narrator exactly at box edge (no gap)
      path.moveTo(centerX, 0); // Start at 0 to touch box bottom

      // Draw curved line to student box center (bottom)
      path.quadraticBezierTo(
        boxCenterX,
        size.height * 0.7, // Control point for curve
        boxCenterX,
        size.height, // End at bottom to touch box top
      );

      canvas.drawPath(path, paint);

      // Draw arrowhead at each student box center pointing down
      final arrowPath = Path();
      final arrowSize = 6.0;

      arrowPath.moveTo(boxCenterX - arrowSize, size.height - arrowSize);
      arrowPath.lineTo(boxCenterX, size.height);
      arrowPath.lineTo(boxCenterX + arrowSize, size.height - arrowSize);

      canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MultipleArrowsPainter extends CustomPainter {
  final int count;
  final Color color;
  final bool isDownward;

  MultipleArrowsPainter({
    required this.count,
    required this.color,
    required this.isDownward,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    // Calculate spacing for arrows
    final spacing = count > 1 ? 120.0 : 0.0;
    final totalWidth = (count - 1) * spacing;
    final startX = centerX - (totalWidth / 2);

    // Draw arrows from each position to center
    for (int i = 0; i < count; i++) {
      final fromX = startX + (i * spacing);
      final fromY = isDownward ? 0.0 : size.height;
      final toY = isDownward ? size.height : 0.0;

      // Draw line from narrator position to center
      final path = Path();
      path.moveTo(fromX, fromY);

      // Draw curved line towards center
      path.quadraticBezierTo(
        fromX,
        fromY + (toY - fromY) * 0.5,
        centerX,
        toY,
      );

      canvas.drawPath(path, paint);

      // Draw arrowhead at center
      final arrowPath = Path();
      final arrowSize = 8.0;

      if (isDownward) {
        arrowPath.moveTo(centerX - arrowSize, size.height - arrowSize);
        arrowPath.lineTo(centerX, size.height);
        arrowPath.lineTo(centerX + arrowSize, size.height - arrowSize);
      } else {
        arrowPath.moveTo(centerX - arrowSize, arrowSize);
        arrowPath.lineTo(centerX, 0);
        arrowPath.lineTo(centerX + arrowSize, arrowSize);
      }

      canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TreeLinePainter extends CustomPainter {
  final Color color;
  final bool isDownward;

  TreeLinePainter({required this.color, required this.isDownward});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final startY = isDownward ? 0.0 : size.height;
    final endY = isDownward ? size.height : 0.0;

    // Draw main vertical line
    canvas.drawLine(
      Offset(centerX, startY),
      Offset(centerX, endY),
      paint,
    );

    // Draw arrow
    final arrowPath = Path();
    if (isDownward) {
      arrowPath.moveTo(centerX - 6, size.height - 6);
      arrowPath.lineTo(centerX, size.height);
      arrowPath.lineTo(centerX + 6, size.height - 6);
    } else {
      arrowPath.moveTo(centerX - 6, 6);
      arrowPath.lineTo(centerX, 0);
      arrowPath.lineTo(centerX + 6, 6);
    }

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
