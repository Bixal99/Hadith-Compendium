import 'package:flutter/material.dart';
import 'package:hadith_iq/components/hover_icon_button.dart';
import 'package:hadith_iq/components/list_tile_vertical.dart';

class MyDrawer extends StatelessWidget {
  final List<MyListTileVert>? vertButtons;
  final List<AnimatedHoverIconButton>? iconButtons;
  final List<Widget>? bottomButtons;
  final String logoImagePath;
  final VoidCallback? onLogoPress;

  const MyDrawer({
    super.key,
    this.vertButtons,
    this.iconButtons,
    this.bottomButtons,
    required this.logoImagePath,
    this.onLogoPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.35),
              offset: const Offset(3, 0),
              blurRadius: 7,
              spreadRadius: 2,
            ),
          ],
        ),
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.only(left: 3, right: 3),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onLogoPress,
                  child: Image.asset(
                    logoImagePath,
                    height: 68.0,
                    width: 68.0,
                  ),
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: (vertButtons ?? iconButtons ?? [])
                  .map((button) => Column(
                        key: ValueKey(button),
                        children: [
                          button,
                          const SizedBox(height: 10),
                        ],
                      ))
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 11, right: 11),
              child: Column(
                children: bottomButtons
                        ?.map((button) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5.0),
                              child: button,
                            ))
                        .toList() ??
                    [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
