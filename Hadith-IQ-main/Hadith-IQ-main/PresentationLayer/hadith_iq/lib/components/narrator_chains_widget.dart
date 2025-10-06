import 'package:flutter/material.dart';

class NarratorChainsWidget extends StatelessWidget {
  final Map<String, dynamic> chainsData;
  final String narratorName;
  final VoidCallback? onRefresh;

  const NarratorChainsWidget({
    super.key,
    required this.chainsData,
    required this.narratorName,
    this.onRefresh,
  });

  // Helper method to check if a chain has valid 3-node structure with unique narrators
  bool _isValidChain(Map<String, dynamic> chain) {
    final chainStructure = chain['chain_structure'] as List<dynamic>? ?? [];

    if (chainStructure.length < 3) return false;

    // Find target narrator
    int targetIndex = chainStructure.indexWhere((e) {
      final m = e as Map<String, dynamic>;
      return (m['is_target'] as bool? ?? false);
    });

    // Fallback: try to match by name
    if (targetIndex == -1 && narratorName.isNotEmpty) {
      targetIndex = chainStructure.indexWhere((e) {
        final m = e as Map<String, dynamic>;
        final name = m['narrator_name'] as String? ?? '';
        return name.trim() == narratorName.trim();
      });
    }

    if (targetIndex == -1 ||
        targetIndex == 0 ||
        targetIndex >= chainStructure.length - 1) {
      return false;
    }

    // Check if all three narrators are unique
    final targetNode = chainStructure[targetIndex] as Map<String, dynamic>;
    final previousNode =
        chainStructure[targetIndex - 1] as Map<String, dynamic>;
    final nextNode = chainStructure[targetIndex + 1] as Map<String, dynamic>;

    final targetName = (targetNode['narrator_name'] as String? ?? '').trim();
    final previousName =
        (previousNode['narrator_name'] as String? ?? '').trim();
    final nextName = (nextNode['narrator_name'] as String? ?? '').trim();

    return targetName.isNotEmpty &&
        previousName.isNotEmpty &&
        nextName.isNotEmpty &&
        targetName != previousName &&
        targetName != nextName &&
        previousName != nextName;
  }

  @override
  Widget build(BuildContext context) {
    final allChains = chainsData['chains'] as List<dynamic>? ?? [];

    // Filter to only show chains with valid 3-node structure (teacher-narrator-student)
    final chains = allChains.where((chain) {
      if (chain is Map<String, dynamic>) {
        return _isValidChain(chain);
      }
      return false;
    }).toList();

    final totalChains = chains.length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'سلاسل الإسناد للراوي: $narratorName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$totalChains سلسلة',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),

          // Chains List
          if (chains.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.link_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد سلاسل إسناد لهذا الراوي',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chains.length,
                itemBuilder: (context, index) {
                  final chain = chains[index] as Map<String, dynamic>;
                  return _buildChainItem(context, chain, index + 1);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChainItem(
      BuildContext context, Map<String, dynamic> chain, int index) {
    final chainStructure = chain['chain_structure'] as List<dynamic>? ?? [];
    final targetLevel = chain['target_narrator_level'] as int? ?? 0;
    final chainLength = chain['chain_length'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'سلسلة $index',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textDirection: TextDirection.rtl,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'المستوى $targetLevel من $chainLength',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 12,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'اضغط لعرض سلسلة الرواة',
            style: Theme.of(context).textTheme.bodySmall,
            textDirection: TextDirection.rtl,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chain visualization only - no hadith text
                _buildChainVisualization(context, chainStructure),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainVisualization(
      BuildContext context, List<dynamic> chainStructure) {
    if (chainStructure.isEmpty) {
      return const Text('لا توجد بيانات للسلسلة',
          textDirection: TextDirection.rtl);
    }

    // Find the target narrator index (clicked narrator) in the chain
    int targetIndex = chainStructure.indexWhere((e) {
      final m = e as Map<String, dynamic>;
      final isTarget = m['is_target'] as bool? ?? false;
      return isTarget;
    });

    // Fallback: if is_target flag isn't present, try to match by narrator name
    if (targetIndex == -1 && narratorName.isNotEmpty) {
      targetIndex = chainStructure.indexWhere((e) {
        final m = e as Map<String, dynamic>;
        final name = m['narrator_name'] as String? ?? '';
        return name.trim() == narratorName.trim();
      });
    }

    // If still not found, default to middle of the chain to avoid crashes
    if (targetIndex == -1) {
      targetIndex = (chainStructure.length / 2).floor();
    }

    // Always display target narrator in center, with unique neighbors only
    // Layout: [LEFT BOX] — [CENTER BOX (TARGET)] — [RIGHT BOX]
    // In RTL: [NEXT] — [TARGET] — [PREVIOUS]

    List<Map<String, dynamic>> displayNodes = [];

    // Only show if chain has exactly 3 nodes: teacher, current narrator, student
    if (chainStructure.length >= 3 && targetIndex >= 0) {
      // Get the target narrator (always goes in center)
      final Map<String, dynamic> targetNode =
          chainStructure[targetIndex] as Map<String, dynamic>;
      final String targetName =
          (targetNode['narrator_name'] as String? ?? '').trim();

      // Get previous narrator (teacher/sheikh - goes on RIGHT in RTL)
      Map<String, dynamic>? previousNode;
      String previousName = '';
      if (targetIndex > 0) {
        previousNode = chainStructure[targetIndex - 1] as Map<String, dynamic>;
        previousName = (previousNode['narrator_name'] as String? ?? '').trim();
      }

      // Get next narrator (student - goes on LEFT in RTL)
      Map<String, dynamic>? nextNode;
      String nextName = '';
      if (targetIndex < chainStructure.length - 1) {
        nextNode = chainStructure[targetIndex + 1] as Map<String, dynamic>;
        nextName = (nextNode['narrator_name'] as String? ?? '').trim();
      }

      // Only display if we have BOTH teacher and student, and all 3 are unique
      if (previousNode != null &&
          nextNode != null &&
          previousName.isNotEmpty &&
          nextName.isNotEmpty &&
          targetName.isNotEmpty &&
          previousName != targetName &&
          nextName != targetName &&
          previousName != nextName) {
        // Build display array: [student] - [current narrator] - [teacher]
        // Ensure is_target flag is properly set for rendering
        displayNodes = [];

        // Student node - not target
        final studentNode = Map<String, dynamic>.from(nextNode);
        studentNode['is_target'] = false;
        displayNodes.add(studentNode);

        // Target node - always the center, mark as target
        final centerNode = Map<String, dynamic>.from(targetNode);
        centerNode['is_target'] = true;
        displayNodes.add(centerNode);

        // Teacher node - not target
        final teacherNode = Map<String, dynamic>.from(previousNode);
        teacherNode['is_target'] = false;
        displayNodes.add(teacherNode);
      }
    }

    // If no valid chain (missing teacher or student, or not unique), don't display anything
    if (displayNodes.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < displayNodes.length; i++) ...[
              _buildNarratorNode(context, displayNodes[i]),
              if (i < displayNodes.length - 1) _buildConnectionLine(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNarratorNode(
      BuildContext context, Map<String, dynamic> narrator) {
    final name = narrator['narrator_name'] as String? ?? '';
    final isTarget = narrator['is_target'] as bool? ?? false;

    // Use primary theme color for center node (target), gray for others
    final nodeColor =
        isTarget ? Theme.of(context).colorScheme.primary : Colors.grey.shade600;

    return Container(
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
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionLine(BuildContext context) {
    // Horizontal connector with arrow pointing left (for RTL, student -> narrator -> teacher)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        size: const Size(60, 30),
        painter: ArrowLinePainter(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }
}

// Custom painter for arrow line
class ArrowLinePainter extends CustomPainter {
  final Color color;

  ArrowLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;

    // Draw horizontal line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );

    // Draw arrow head pointing left (<-)
    final arrowPath = Path();
    final arrowSize = 8.0;

    arrowPath.moveTo(0, centerY); // Arrow tip
    arrowPath.lineTo(arrowSize, centerY - arrowSize); // Top point
    arrowPath.lineTo(arrowSize, centerY + arrowSize); // Bottom point
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
