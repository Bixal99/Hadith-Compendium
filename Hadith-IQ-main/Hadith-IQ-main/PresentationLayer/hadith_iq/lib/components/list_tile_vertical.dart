import 'package:flutter/material.dart';

class MyListTileVert extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Icon icon;
  final bool isSelected;

  const MyListTileVert(
      {super.key,
      required this.text,
      required this.onTap,
      required this.icon,
      this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary, // Color for the selected border
                    width: 2.0,
                  ),
                )
              : null,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(7),
            bottomLeft: Radius.circular(7),
          ), // No border if not selected
        ),
        child: SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
