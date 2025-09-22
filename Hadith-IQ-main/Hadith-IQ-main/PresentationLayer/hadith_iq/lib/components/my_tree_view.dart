// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:popover/popover.dart';

// enum LineStyle { curved, stepped, rounded, dashed }

// enum TreeDirection { vertical, horizontal }

// class TreeNode {
//   final String value;
//   final List<TreeNode> children;
//   final GlobalKey nodeKey;
//   final Color color;
//   double x = 0;
//   double y = 0;

//   TreeNode({
//     required this.value,
//     this.children = const [],
//     this.color = const Color(0xFFD6C091),
//     GlobalKey? key,
//   }) : nodeKey = key ?? GlobalKey();
// }

// class TreeViewWidget extends StatefulWidget {
//   final TreeNode nodeData;
//   final LineStyle lineStyle;
//   final TreeDirection direction;
//   final void Function(String)? onNodeClick;
//   final Future<bool> Function(String)? onNodeRightClick;
//   final void Function(String, String)? onListItemClick;
//   final List<String> itemsOnRightClick;
//   final bool isNodeClickable;

//   const TreeViewWidget({
//     super.key,
//     required this.nodeData,
//     this.lineStyle = LineStyle.stepped,
//     this.direction = TreeDirection.horizontal,
//     this.onNodeClick,
//     this.onNodeRightClick,
//     this.itemsOnRightClick = const [],
//     this.onListItemClick,
//     this.isNodeClickable = false,
//   });

//   @override
//   TreeViewWidgetState createState() => TreeViewWidgetState();
// }

// class TreeViewWidgetState extends State<TreeViewWidget>
//     with WidgetsBindingObserver {
//   late final LineStyle lineStyle;
//   late final TreeDirection direction;
//   late final TreeNode rootNode;
//   final GlobalKey nodeKey = GlobalKey();

//   final double _nodeWidth = 145;
//   final double _nodeHeight = 50;
//   double _verticalSpacing = 0;
//   double _horizontalSpacing = 0;
//   double _treeWidth = 0;
//   double _treeHeight = 0;
//   late BuildContext popoverContext;
//   bool isPopoverOpened = false;

//   @override
//   void initState() {
//     super.initState();
//     rootNode = widget.nodeData;
//     lineStyle = widget.lineStyle;
//     direction = widget.direction;
//     _verticalSpacing = direction == TreeDirection.vertical ? 100 : 30;
//     _horizontalSpacing = direction == TreeDirection.horizontal ? 200 : 30;
//     _calculateTreeDimensions();
//     // Add the observer to listen for screen size changes
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     // Remove the observer when the widget is disposed
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   // This will be triggered whenever screen metrics change (e.g., resizing)
//   @override
//   void didChangeMetrics() {
//     super.didChangeMetrics();
//     if (MediaQuery.of(context).size.height < 650 ||
//         MediaQuery.of(context).size.width < 1200) {
//       if (isPopoverOpened) {
//         if (Navigator.of(popoverContext).canPop()) {
//           Navigator.of(popoverContext).maybePop();
//         }
//       }
//     }
//   }

//   void _showPopover(GlobalKey nodeKey, String nodeItemName) {
//     // Use the button's context (via its GlobalKey) to anchor the popover
//     final BuildContext nodeContext = nodeKey.currentContext!;
//     showPopover(
//       context: nodeContext,
//       bodyBuilder: (context) {
//         // Schedule the state change after the current frame is done
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted) {
//             setState(() {
//               isPopoverOpened = true;
//               popoverContext = context;
//             });
//           }
//         });
//         return NodeClickDropdownMenuItems(
//           onItemClick: widget.isNodeClickable
//               ? (listItem) {
//                   widget.onListItemClick?.call(listItem, nodeItemName);
//                   if (Navigator.of(context).canPop()) {
//                     Navigator.of(context).maybePop();
//                   }
//                 }
//               : (item) {},
//           itemsOnRightClick: widget.itemsOnRightClick,
//         );
//       },
//       height: 175,
//       width: 275,
//       backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
//       direction: PopoverDirection.bottom,
//       barrierColor: Colors.transparent, // Optional: make barrier transparent
//       onPop: () {
//         if (mounted) {
//           setState(() => isPopoverOpened = false);
//         }
//       },
//     );
//   }
//   void _calculateTreeDimensions() {
//     if (direction == TreeDirection.vertical) {
//       _treeWidth = _calculateSubtreeWidth(rootNode);
//       _treeHeight = _calculateTreeDepth(rootNode) * _verticalSpacing;
//     } else {
//       _treeWidth = _calculateTreeDepth(rootNode) * _horizontalSpacing;
//       _treeHeight = _calculateSubtreeHeight(rootNode);
//     }
//     _calculateNodePositions(rootNode, 0, 0);
//   }

//   // Add horizontal layout calculations
//   double _calculateSubtreeHeight(TreeNode node) {
//     if (node.children.isEmpty) return _nodeHeight;
//     double total = 0;
//     for (var child in node.children) {
//       total += _calculateSubtreeHeight(child);
//     }
//     return total + (_verticalSpacing * (node.children.length - 1));
//   }

//   double _calculateSubtreeWidth(TreeNode node) {
//     if (node.children.isEmpty) return _nodeWidth;
//     double total = 0;
//     for (var child in node.children) {
//       total += _calculateSubtreeWidth(child);
//     }
//     return total + (_horizontalSpacing * (node.children.length - 1));
//   }

//   int _calculateTreeDepth(TreeNode node) {
//     if (node.children.isEmpty) return 1;
//     int maxDepth = 0;
//     for (var child in node.children) {
//       maxDepth = max(maxDepth, _calculateTreeDepth(child));
//     }
//     return 1 + maxDepth;
//   }

//   void _calculateNodePositions(TreeNode node, double start, int depth) {
//     if (direction == TreeDirection.vertical) {
//       // Vertical layout calculations
//       node.y = depth * _verticalSpacing;

//       if (node.children.isEmpty) {
//         node.x = start;
//         return;
//       }

//       double currentX = start;
//       for (var child in node.children) {
//         final childWidth = _calculateSubtreeWidth(child);
//         _calculateNodePositions(child, currentX, depth + 1);
//         currentX += childWidth + _horizontalSpacing;
//       }

//       final firstChild = node.children.first;
//       final lastChild = node.children.last;
//       node.x = (firstChild.x + lastChild.x) / 2;
//     } else {
//       // Horizontal layout calculations
//       node.x = depth * _horizontalSpacing;

//       if (node.children.isEmpty) {
//         node.y = start;
//         return;
//       }

//       double currentY = start;
//       for (var child in node.children) {
//         final childHeight = _calculateSubtreeHeight(child);
//         _calculateNodePositions(child, currentY, depth + 1);
//         currentY += childHeight + _verticalSpacing;
//       }

//       final firstChild = node.children.first;
//       final lastChild = node.children.last;
//       node.y = (firstChild.y + lastChild.y) / 2;
//     }
//   }

//   @override
// Widget build(BuildContext context) {
//   final horizontalController = ScrollController();
//   final verticalController = ScrollController();

//   return LayoutBuilder(
//     builder: (context, constraints) {
//       return Scrollbar(
//         controller: verticalController,
//         thumbVisibility: true,
//         notificationPredicate: (_) => true,
//         child: SingleChildScrollView(
//           controller: verticalController,
//           scrollDirection: Axis.vertical,
//           child: Scrollbar(
//             controller: horizontalController,
//             thumbVisibility: true,
//             notificationPredicate: (_) => true,
//             child: SingleChildScrollView(
//               controller: horizontalController,
//               scrollDirection: Axis.horizontal,
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   minWidth: max(_treeWidth + _nodeWidth, constraints.maxWidth),
//                   minHeight:
//                       max(_treeHeight + _nodeHeight, constraints.maxHeight),
//                 ),
//                 child: Center(
//                   child: SizedBox(
//                     width: _treeWidth,
//                     height: _treeHeight,
//                     child: Stack(
//                       children: [
//                         CustomPaint(
//                           size: Size(
//                             _treeWidth + _nodeWidth,
//                             _treeHeight + _nodeHeight,
//                           ),
//                           painter: TreePainter(
//                             rootNode,
//                             context,
//                             direction,
//                             nodeWidth: _nodeWidth,
//                             nodeHeight: _nodeHeight,
//                             lineStyle: lineStyle,
//                           ),
//                         ),
//                         ..._buildNodes(rootNode),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }

//   List<Widget> _buildNodes(TreeNode node) {
//     var tempNodeHeight =
//         node.value.length < 35 ? _nodeHeight : _nodeHeight + 10;
//     final nodes = <Widget>[
//       Positioned(
//         left: direction == TreeDirection.vertical ? node.x : node.x,
//         top: direction == TreeDirection.vertical ? node.y : node.y,
//         child: MouseRegion(
//           cursor: widget.isNodeClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
//           child: GestureDetector(
//             onTap: widget.isNodeClickable
//                 ? () {
//                     widget.onNodeClick?.call(node.value);
//                   }
//                 : () {},
//             onSecondaryTap: () async {
//               bool success = await (widget.onNodeRightClick?.call(node.value) ??
//                   Future.value(false));
//               if (success) {
//                 _showPopover(node.nodeKey, node.value);
//               }
//             },
//             child: Container(
//               key: node.nodeKey,
//               width: _nodeWidth,
//               height: tempNodeHeight,
//               decoration: BoxDecoration(
//                 color: node.color,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black.withValues(alpha: 0.1),
//                       blurRadius: 4,
//                       offset: const Offset(2, 2)),
//                 ],
//               ),
//               child: Directionality(
//                 textDirection: TextDirection.rtl,
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Center(
//                     child: Text(
//                       node.value,
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.onSecondary,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     ];

//     for (var child in node.children) {
//       nodes.addAll(_buildNodes(child));
//     }

//     return nodes;
//   }
// }

// class TreePainter extends CustomPainter {
//   final TreeNode rootNode;
//   final double nodeWidth;
//   final double nodeHeight;
//   final LineStyle lineStyle;
//   final TreeDirection direction;
//   final BuildContext context;

//   TreePainter(
//     this.rootNode,
//     this.context,
//     this.direction, {
//     required this.nodeWidth,
//     required this.nodeHeight,
//     this.lineStyle = LineStyle.curved,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     _drawConnections(canvas, rootNode, size);
//   }

//   void _drawConnections(Canvas canvas, TreeNode node, Size size) {
//     final paint = Paint()
//       ..color = Theme.of(context).colorScheme.primary
//       ..strokeWidth = 2
//       ..style = PaintingStyle.stroke;

//     if (lineStyle == LineStyle.dashed) {
//       paint.strokeCap = StrokeCap.round;
//     }

//     for (final child in node.children) {
//       final parentCenter = direction == TreeDirection.vertical
//           ? Offset(node.x + nodeWidth / 2, node.y + nodeHeight)
//           : Offset(node.x + nodeWidth, node.y + nodeHeight / 2);

//       final childCenter = direction == TreeDirection.vertical
//           ? Offset(child.x + nodeWidth / 2, child.y)
//           : Offset(child.x, child.y + nodeHeight / 2);

//       switch (lineStyle) {
//         case LineStyle.curved:
//           _drawCurvedConnection(canvas, parentCenter, childCenter, paint);
//           break;
//         case LineStyle.stepped:
//           _drawSteppedConnection(canvas, parentCenter, childCenter, paint);
//           break;
//         case LineStyle.rounded:
//           _drawRoundedConnection(canvas, parentCenter, childCenter, paint);
//           break;
//         case LineStyle.dashed:
//           _drawDashedConnection(canvas, parentCenter, childCenter, paint);
//           break;
//       }

//       _drawConnections(canvas, child, size);
//     }
//   }

//   void _drawCurvedConnection(
//       Canvas canvas, Offset start, Offset end, Paint paint) {
//     final path = Path();
//     if (direction == TreeDirection.vertical) {
//       path.moveTo(start.dx, start.dy);
//       path.quadraticBezierTo(
//         start.dx,
//         start.dy + (end.dy - start.dy) * 0.5,
//         end.dx,
//         end.dy,
//       );
//     } else {
//       path.moveTo(start.dx, start.dy);
//       path.quadraticBezierTo(
//         start.dx + (end.dx - start.dx) * 0.5,
//         start.dy,
//         end.dx,
//         end.dy,
//       );
//     }
//     canvas.drawPath(path, paint);
//   }

//   void _drawSteppedConnection(
//       Canvas canvas, Offset start, Offset end, Paint paint) {
//     final path = Path();
//     if (direction == TreeDirection.vertical) {
//       final middleY = start.dy + (end.dy - start.dy) * 0.5;
//       path.moveTo(start.dx, start.dy);
//       path.lineTo(start.dx, middleY);
//       path.lineTo(end.dx, middleY);
//       path.lineTo(end.dx, end.dy);
//     } else {
//       final middleX = start.dx + (end.dx - start.dx) * 0.5;
//       path.moveTo(start.dx, start.dy);
//       path.lineTo(middleX, start.dy);
//       path.lineTo(middleX, end.dy);
//       path.lineTo(end.dx, end.dy);
//     }
//     canvas.drawPath(path, paint);
//   }

//   void _drawRoundedConnection(
//       Canvas canvas, Offset start, Offset end, Paint paint) {
//     final path = Path();
//     if (direction == TreeDirection.vertical) {
//       final middleY = start.dy + (end.dy - start.dy) * 0.5;
//       path.moveTo(start.dx, start.dy);
//       path.lineTo(start.dx, middleY - 20);
//       path.quadraticBezierTo(
//         start.dx,
//         middleY,
//         start.dx + (end.dx - start.dx).sign * 20,
//         middleY,
//       );
//       path.lineTo(end.dx - (end.dx - start.dx).sign * 20, middleY);
//       path.quadraticBezierTo(
//         end.dx,
//         middleY,
//         end.dx,
//         middleY + 20,
//       );
//       path.lineTo(end.dx, end.dy);
//     } else {
//       final middleX = start.dx + (end.dx - start.dx) * 0.5;
//       path.moveTo(start.dx, start.dy);
//       path.lineTo(middleX - 20, start.dy);
//       path.quadraticBezierTo(
//         middleX,
//         start.dy,
//         middleX,
//         start.dy + (end.dy - start.dy).sign * 20,
//       );
//       path.lineTo(middleX, end.dy - (end.dy - start.dy).sign * 20);
//       path.quadraticBezierTo(
//         middleX,
//         end.dy,
//         middleX + 20,
//         end.dy,
//       );
//       path.lineTo(end.dx, end.dy);
//     }
//     canvas.drawPath(path, paint);
//   }

//   void _drawDashedConnection(
//       Canvas canvas, Offset start, Offset end, Paint paint) {
//     final path = Path()
//       ..moveTo(start.dx, start.dy)
//       ..lineTo(end.dx, end.dy);
//     final dashPath = Path();
//     final pathMetrics = path.computeMetrics();

//     for (final metric in pathMetrics) {
//       double distance = 0;
//       while (distance < metric.length) {
//         dashPath.addPath(
//           metric.extractPath(distance, distance + 5),
//           Offset.zero,
//         );
//         distance += 10;
//       }
//     }

//     canvas.drawPath(dashPath, paint);
//   }
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }

// class NodeClickDropdownMenuItems extends StatefulWidget {
//   final Function(String)? onItemClick;
//   final List<String> itemsOnRightClick;

//   const NodeClickDropdownMenuItems({
//     super.key,
//     required this.onItemClick,
//     required this.itemsOnRightClick,
//   });

//   @override
//   State<NodeClickDropdownMenuItems> createState() =>
//       _NodeClickDropdownMenuItemsState();
// }

// class _NodeClickDropdownMenuItemsState
//     extends State<NodeClickDropdownMenuItems> {
//   late final ScrollController _scrollController;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Column(
//         children: [
//           SizedBox(
//             width: 250,
//             height: 155,
//             child: Scrollbar(
//               controller: _scrollController,
//               thumbVisibility: true,
//               child: ListView.builder(
//                 controller: _scrollController,
//                 itemCount: widget.itemsOnRightClick.length,
//                 itemBuilder: (context, index) {
//                   return DropdownListItem(
//                     itemName: widget.itemsOnRightClick[index],
//                     index: index,
//                     onTap: (i) {
//                       widget.onItemClick?.call(widget.itemsOnRightClick[i]);
//                     },
//                   );
//                 },
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

// class DropdownListItem extends StatefulWidget {
//   final String itemName;
//   final int index;
//   final Function(int) onTap;

//   const DropdownListItem({
//     super.key,
//     required this.itemName,
//     required this.index,
//     required this.onTap,
//   });

//   @override
//   DropdownListItemState createState() => DropdownListItemState();
// }

// class DropdownListItemState extends State<DropdownListItem> {
//   final ValueNotifier<bool> _isHovered = ValueNotifier(false);

//   @override
//   void dispose() {
//     _isHovered.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       cursor: SystemMouseCursors.click,
//       onEnter: (_) => _isHovered.value = true,
//       onExit: (_) => _isHovered.value = false,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => widget.onTap(widget.index),
//         child: ValueListenableBuilder<bool>(
//           valueListenable: _isHovered,
//           builder: (context, isHovered, child) {
//             return Directionality(
//               textDirection: TextDirection.rtl,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 150),
//                 margin: const EdgeInsets.symmetric(vertical: 1),
//                 padding: const EdgeInsets.only(
//                     right: 13, left: 13, top: 9, bottom: 9),
//                 decoration: BoxDecoration(
//                   color: isHovered
//                       ? Theme.of(context).colorScheme.secondary
//                       : Theme.of(context).colorScheme.surface,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: Theme.of(context).colorScheme.secondary,
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Text(
//                         widget.itemName,
//                         style: TextStyle(
//                           color: isHovered
//                               ? Theme.of(context).colorScheme.onSecondary
//                               : Theme.of(context).colorScheme.onSurface,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         softWrap: false,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:popover/popover.dart';

enum LineStyle { curved, stepped, rounded, dashed }

enum TreeDirection { vertical, horizontal }

enum TreeLayout { standard, bidirectional }

class TreeNode {
  final String value;
  final List<TreeNode> children;
  final GlobalKey nodeKey;
  final Color color;
  final bool isAbove; // New flag for bidirectional layout
  double x = 0;
  double y = 0;

  TreeNode({
    required this.value,
    this.children = const [],
    this.color = const Color(0xFFD6C091),
    this.isAbove = false, // Default to below
    GlobalKey? key,
  }) : nodeKey = key ?? GlobalKey();
}

class TreeViewWidget extends StatefulWidget {
  final TreeNode nodeData;
  final LineStyle lineStyle;
  final TreeDirection direction;
  final TreeLayout layout; // New layout option
  final void Function(String)? onNodeClick;
  final Future<bool> Function(String)? onNodeRightClick;
  final void Function(String, String)? onListItemClick;
  final List<String> itemsOnRightClick;
  final bool isNodeClickable;

  const TreeViewWidget({
    super.key,
    required this.nodeData,
    this.lineStyle = LineStyle.stepped,
    this.direction = TreeDirection.horizontal,
    this.layout = TreeLayout.standard, // Default to standard layout
    this.onNodeClick,
    this.onNodeRightClick,
    this.itemsOnRightClick = const [],
    this.onListItemClick,
    this.isNodeClickable = false,
  });

  @override
  TreeViewWidgetState createState() => TreeViewWidgetState();
}

class TreeViewWidgetState extends State<TreeViewWidget>
    with WidgetsBindingObserver {
  late final LineStyle lineStyle;
  late final TreeDirection direction;
  late final TreeLayout layout;
  late final TreeNode rootNode;
  final GlobalKey nodeKey = GlobalKey();

  final double _nodeWidth = 155;
  final double _nodeHeight = 50;
  double _verticalSpacing = 0;
  double _horizontalSpacing = 0;
  double _treeWidth = 0;
  double _treeHeight = 0;
  late BuildContext popoverContext;
  bool isPopoverOpened = false;

  // Add ScrollController fields
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    rootNode = widget.nodeData;
    lineStyle = widget.lineStyle;
    direction = widget.direction;
    layout = widget.layout;
    _verticalSpacing = direction == TreeDirection.vertical ? 100 : 30;
    _horizontalSpacing = direction == TreeDirection.horizontal ? 200 : 30;
    _calculateTreeDimensions();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Dispose of ScrollControllers
    _verticalController.dispose();
    _horizontalController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (MediaQuery.of(context).size.height < 650 ||
        MediaQuery.of(context).size.width < 1200) {
      if (isPopoverOpened && Navigator.of(popoverContext).canPop()) {
        Navigator.of(popoverContext).maybePop();
      }
    }
  }

  void _showPopover(GlobalKey nodeKey, String nodeItemName) {
    final BuildContext nodeContext = nodeKey.currentContext!;
    showPopover(
      context: nodeContext,
      bodyBuilder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              isPopoverOpened = true;
              popoverContext = context;
            });
          }
        });
        return NodeClickDropdownMenuItems(
          onItemClick: widget.isNodeClickable
              ? (listItem) {
                  widget.onListItemClick?.call(listItem, nodeItemName);
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).maybePop();
                  }
                }
              : (item) {},
          itemsOnRightClick: widget.itemsOnRightClick,
        );
      },
      height: 175,
      width: 275,
      backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
      direction: PopoverDirection.bottom,
      barrierColor: Colors.transparent,
      onPop: () {
        if (mounted) {
          setState(() => isPopoverOpened = false);
        }
      },
    );
  }

// For bidirectional layout (handles List<TreeNode>)
  double _calculateSubtreeWidthForNodes(List<TreeNode> nodes) {
    if (nodes.isEmpty) return _nodeWidth;
    double total = 0;
    for (var node in nodes) {
      total +=
          _calculateSubtreeWidth(node); // Use single-node version for children
    }
    return total + (_horizontalSpacing * (nodes.length - 1));
  }

  int _calculateTreeDepthForNodes(List<TreeNode> nodes) {
    if (nodes.isEmpty) return 0;
    int maxDepth = 0;
    for (var node in nodes) {
      maxDepth =
          max(maxDepth, _calculateTreeDepth(node)); // Use single-node version
    }
    return 1 + maxDepth;
  }

// Restored single-node methods for standard layout
  double _calculateSubtreeWidth(TreeNode node) {
    if (node.children.isEmpty) return _nodeWidth;
    double total = 0;
    for (var child in node.children) {
      total += _calculateSubtreeWidth(child);
    }
    return total + (_horizontalSpacing * (node.children.length - 1));
  }

  int _calculateTreeDepth(TreeNode node) {
    if (node.children.isEmpty) return 1;
    int maxDepth = 0;
    for (var child in node.children) {
      maxDepth = max(maxDepth, _calculateTreeDepth(child));
    }
    return 1 + maxDepth;
  }

  void _calculateTreeDimensions() {
    if (layout == TreeLayout.bidirectional) {
      _calculateBidirectionalDimensions();
    } else {
      if (direction == TreeDirection.vertical) {
        _treeWidth =
            _calculateSubtreeWidth(rootNode); // Use single-node version
        _treeHeight = _calculateTreeDepth(rootNode) *
            _verticalSpacing; // Use single-node version
      } else {
        _treeWidth = _calculateTreeDepth(rootNode) *
            _horizontalSpacing; // Use single-node version
        _treeHeight = _calculateSubtreeHeight(rootNode);
      }
      _calculateNodePositions(rootNode, 0, 0);
    }
  }

  void _calculateBidirectionalDimensions() {
    final aboveChildren =
        rootNode.children.where((child) => child.isAbove).toList();
    final belowChildren =
        rootNode.children.where((child) => !child.isAbove).toList();

    final aboveWidth = aboveChildren.isNotEmpty
        ? _calculateSubtreeWidthForNodes(aboveChildren)
        : _nodeWidth;
    final belowWidth = belowChildren.isNotEmpty
        ? _calculateSubtreeWidthForNodes(belowChildren)
        : _nodeWidth;
    final aboveHeight = aboveChildren.isNotEmpty
        ? _calculateTreeDepthForNodes(aboveChildren) * _verticalSpacing +
            _nodeHeight
        : 0;
    final belowHeight = belowChildren.isNotEmpty
        ? _calculateTreeDepthForNodes(belowChildren) * _verticalSpacing +
            _nodeHeight
        : 0;

    _treeWidth = max(aboveWidth, belowWidth);
    _treeHeight =
        aboveHeight + belowHeight + _nodeHeight + _verticalSpacing * 2;

    final centerX = _treeWidth / 2;
    final centerY = aboveHeight +
        _verticalSpacing; // Root centered relative to above subtree
    _calculateBidirectionalNodePositions(rootNode, centerX, centerY);
  }

  void _calculateBidirectionalNodePositions(
      TreeNode node, double centerX, double centerY) {
    node.x = centerX - _nodeWidth / 2;
    node.y = centerY - _nodeHeight / 2;

    final aboveChildren =
        node.children.where((child) => child.isAbove).toList();
    final belowChildren =
        node.children.where((child) => !child.isAbove).toList();

    // Position above children
    double currentX =
        centerX - (_calculateSubtreeWidthForNodes(aboveChildren) / 2);
    for (var child in aboveChildren) {
      final childWidth = _calculateSubtreeWidth(child);
      final childCenterX = currentX + childWidth / 2;
      final childCenterY = centerY - _verticalSpacing - _nodeHeight / 2;
      _calculateBidirectionalNodePositions(child, childCenterX, childCenterY);
      currentX += childWidth + _horizontalSpacing;
    }

    // Position below children
    currentX = centerX - (_calculateSubtreeWidthForNodes(belowChildren) / 2);
    for (var child in belowChildren) {
      final childWidth = _calculateSubtreeWidth(child);
      final childCenterX = currentX + childWidth / 2;
      final childCenterY = centerY + _verticalSpacing + _nodeHeight / 2;
      _calculateBidirectionalNodePositions(child, childCenterX, childCenterY);
      currentX += childWidth + _horizontalSpacing;
    }
  }

  double _calculateSubtreeHeight(TreeNode node) {
    if (node.children.isEmpty) return _nodeHeight;
    double total = 0;
    for (var child in node.children) {
      total += _calculateSubtreeHeight(child);
    }
    return total + (_verticalSpacing * (node.children.length - 1));
  }

  void _calculateNodePositions(TreeNode node, double startX, int depth) {
    if (direction == TreeDirection.vertical) {
      node.y = depth * _verticalSpacing;
      if (node.children.isEmpty) {
        node.x = startX + _nodeWidth / 2;
        return;
      }
      double currentX = startX;
      final subtreeWidth = _calculateSubtreeWidth(node);
      for (var child in node.children) {
        final childWidth = _calculateSubtreeWidth(child);
        _calculateNodePositions(child, currentX, depth + 1);
        currentX += childWidth + _horizontalSpacing;
      }
      node.x = startX + subtreeWidth / 2 - _nodeWidth / 2;
    } else {
      node.x = depth * _horizontalSpacing;
      if (node.children.isEmpty) {
        node.y = startX + _nodeHeight / 2;
        return;
      }
      double currentY = startX;
      for (var child in node.children) {
        final childHeight = _calculateSubtreeHeight(child);
        _calculateNodePositions(child, currentY, depth + 1);
        currentY += childHeight + _verticalSpacing;
      }
      if (node.children.isNotEmpty) {
        final firstChild = node.children.first;
        final lastChild = node.children.last;
        node.y = (firstChild.y + lastChild.y) / 2;
      } else {
        node.y = startX + _nodeHeight / 2;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: max(constraints.maxWidth, _treeWidth),
                    minHeight: max(constraints.maxHeight, _treeHeight),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(
                              _treeWidth + _nodeWidth,
                              _treeHeight + _nodeHeight,
                            ),
                            painter: TreePainter(
                              rootNode,
                              context,
                              direction,
                              layout: layout,
                              nodeWidth: _nodeWidth,
                              nodeHeight: _nodeHeight,
                              lineStyle: lineStyle,
                            ),
                          ),
                          ..._buildNodes(rootNode),
                        ],
                      ),
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

  List<Widget> _buildNodes(TreeNode node) {
    var tempNodeHeight =
        node.value.length < 20 ? _nodeHeight : _nodeHeight + 10;
    final nodes = <Widget>[
      Positioned(
        left: node.x,
        top: node.y,
        child: MouseRegion(
          cursor: widget.isNodeClickable
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: widget.isNodeClickable
                ? () => widget.onNodeClick?.call(node.value)
                : () {},
            onSecondaryTap: () async {
              bool success = await (widget.onNodeRightClick?.call(node.value) ??
                  Future.value(false));
              if (success) {
                _showPopover(node.nodeKey, node.value);
              }
            },
            child: Container(
              key: node.nodeKey,
              width: _nodeWidth,
              height: tempNodeHeight,
              decoration: BoxDecoration(
                color: node.color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      node.value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center, // Ensure text is centered
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ];

    for (var child in node.children) {
      nodes.addAll(_buildNodes(child));
    }

    return nodes;
  }
}

class TreePainter extends CustomPainter {
  final TreeNode rootNode;
  final double nodeWidth;
  final double nodeHeight;
  final LineStyle lineStyle;
  final TreeDirection direction;
  final TreeLayout layout;
  final BuildContext context;

  TreePainter(
    this.rootNode,
    this.context,
    this.direction, {
    required this.nodeWidth,
    required this.nodeHeight,
    required this.layout,
    this.lineStyle = LineStyle.curved,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnections(canvas, rootNode, size);
  }

  void _drawConnections(Canvas canvas, TreeNode node, Size size) {
    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (lineStyle == LineStyle.dashed) {
      paint.strokeCap = StrokeCap.round;
    }

    for (final child in node.children) {
      final parentCenter = layout == TreeLayout.bidirectional
          ? Offset(
              node.x + nodeWidth / 2,
              node.y + (child.isAbove ? 0 : nodeHeight),
            )
          : direction == TreeDirection.vertical
              ? Offset(node.x + nodeWidth / 2, node.y + nodeHeight)
              : Offset(node.x + nodeWidth, node.y + nodeHeight / 2);

      final childCenter = layout == TreeLayout.bidirectional
          ? Offset(
              child.x + nodeWidth / 2,
              child.y + (child.isAbove ? nodeHeight : 0),
            )
          : direction == TreeDirection.vertical
              ? Offset(child.x + nodeWidth / 2, child.y)
              : Offset(child.x, child.y + nodeHeight / 2);

      switch (lineStyle) {
        case LineStyle.curved:
          _drawCurvedConnection(canvas, parentCenter, childCenter, paint);
          break;
        case LineStyle.stepped:
          _drawSteppedConnection(canvas, parentCenter, childCenter, paint);
          break;
        case LineStyle.rounded:
          _drawRoundedConnection(canvas, parentCenter, childCenter, child, paint);
          break;
        case LineStyle.dashed:
          _drawDashedConnection(canvas, parentCenter, childCenter, paint);
          break;
      }

      _drawConnections(canvas, child, size);
    }
  }

  void _drawCurvedConnection(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    if (layout == TreeLayout.bidirectional ||
        direction == TreeDirection.vertical) {
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(
        start.dx,
        start.dy + (end.dy - start.dy) * 0.5,
        end.dx,
        end.dy,
      );
    } else {
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(
        start.dx + (end.dx - start.dx) * 0.5,
        start.dy,
        end.dx,
        end.dy,
      );
    }
    canvas.drawPath(path, paint);
  }

  void _drawSteppedConnection(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    if (layout == TreeLayout.bidirectional ||
        direction == TreeDirection.vertical) {
      final middleY = start.dy + (end.dy - start.dy) * 0.5;
      path.moveTo(start.dx, start.dy);
      path.lineTo(start.dx, middleY);
      path.lineTo(end.dx, middleY);
      path.lineTo(end.dx, end.dy);
    } else {
      final middleX = start.dx + (end.dx - start.dx) * 0.5;
      path.moveTo(start.dx, start.dy);
      path.lineTo(middleX, start.dy);
      path.lineTo(middleX, end.dy);
      path.lineTo(end.dx, end.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawRoundedConnection(
      Canvas canvas, Offset start, Offset end, TreeNode child, Paint paint) {
    final path = Path();
    if (layout == TreeLayout.bidirectional ||
        direction == TreeDirection.vertical) {
      path.moveTo(start.dx, start.dy);
      final controlY = start.dy + (end.dy - start.dy) * (child.isAbove ? 0.3 : 0.7);
      path.quadraticBezierTo(
        start.dx + (end.dx - start.dx) * 0.5,
        controlY,
        end.dx,
        end.dy,
      );
    } else {
      path.moveTo(start.dx, start.dy);
      final controlX = start.dx + (end.dx - start.dx) * 0.7;
      path.quadraticBezierTo(
        controlX,
        start.dy + (end.dy - start.dy) * 0.5,
        end.dx,
        end.dy,
      );
    }
    canvas.drawPath(path, paint);
  }

  void _drawDashedConnection(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
    final dashPath = Path();
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + 5),
          Offset.zero,
        );
        distance += 10;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NodeClickDropdownMenuItems extends StatefulWidget {
  final Function(String)? onItemClick;
  final List<String> itemsOnRightClick;

  const NodeClickDropdownMenuItems({
    super.key,
    required this.onItemClick,
    required this.itemsOnRightClick,
  });

  @override
  State<NodeClickDropdownMenuItems> createState() =>
      _NodeClickDropdownMenuItemsState();
}

class _NodeClickDropdownMenuItemsState
    extends State<NodeClickDropdownMenuItems> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(
            width: 250,
            height: 155,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: widget.itemsOnRightClick.length,
                itemBuilder: (context, index) {
                  return DropdownListItem(
                    itemName: widget.itemsOnRightClick[index],
                    index: index,
                    onTap: (i) {
                      widget.onItemClick?.call(widget.itemsOnRightClick[i]);
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class DropdownListItem extends StatefulWidget {
  final String itemName;
  final int index;
  final Function(int) onTap;

  const DropdownListItem({
    super.key,
    required this.itemName,
    required this.index,
    required this.onTap,
  });

  @override
  DropdownListItemState createState() => DropdownListItemState();
}

class DropdownListItemState extends State<DropdownListItem> {
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
                margin: const EdgeInsets.symmetric(vertical: 1),
                padding: const EdgeInsets.only(
                    right: 13, left: 13, top: 9, bottom: 9),
                decoration: BoxDecoration(
                  color: isHovered
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.itemName,
                        style: TextStyle(
                          color: isHovered
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
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
