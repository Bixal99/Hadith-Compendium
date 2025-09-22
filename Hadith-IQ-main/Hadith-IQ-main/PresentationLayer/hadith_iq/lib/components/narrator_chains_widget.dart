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

  @override
  Widget build(BuildContext context) {
    final chains = chainsData['chains'] as List<dynamic>? ?? [];
    final totalChains = chainsData['total_chains'] as int? ?? 0;

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

    if (chainStructure.length >= 3) {
      // Get the target narrator (always goes in center)
      final Map<String, dynamic> targetNode =
          chainStructure[targetIndex] as Map<String, dynamic>;

      // Get previous narrator (goes on RIGHT in RTL) - must be unique
      Map<String, dynamic>? previousNode;
      if (targetIndex > 0) {
        previousNode = chainStructure[targetIndex - 1] as Map<String, dynamic>;
      }

      // Get next narrator (goes on LEFT in RTL) - must be unique
      Map<String, dynamic>? nextNode;
      if (targetIndex < chainStructure.length - 1) {
        nextNode = chainStructure[targetIndex + 1] as Map<String, dynamic>;
      }

      // Build display array with only unique narrators
      displayNodes = [];
      if (nextNode != null) {
        displayNodes.add(nextNode); // Left box
      }
      displayNodes.add(targetNode); // Center box (always the target)
      if (previousNode != null) {
        displayNodes.add(previousNode); // Right box
      }
    } else {
      // For chains with less than 3 narrators, show all available
      displayNodes = chainStructure.cast<Map<String, dynamic>>();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < displayNodes.length; i++) ...[
            _buildNarratorNode(context, displayNodes[i]),
            if (i < displayNodes.length - 1) _buildConnectionLine(context),
          ],
        ],
      ),
    );
  }

  Widget _buildNarratorNode(
      BuildContext context, Map<String, dynamic> narrator) {
    final name = narrator['narrator_name'] as String? ?? '';
    final level = narrator['level'] as int? ?? 0;
    final isTarget = narrator['is_target'] as bool? ?? false;

    return Container(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
      child: Column(
        children: [
          // Level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isTarget
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$level',
              style: TextStyle(
                color: isTarget
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Narrator name box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isTarget
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: isTarget
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Text(
              name,
              style: TextStyle(
                color: isTarget
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionLine(BuildContext context) {
    // Simple horizontal connector; kept neutral to work for RTL and LTR.
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 2,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
