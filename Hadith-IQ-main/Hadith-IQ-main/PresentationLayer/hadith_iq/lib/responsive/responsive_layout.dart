import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileScaffold;
  final Widget tabletScaffold;
  final Widget dekstopScaffold;

  const ResponsiveLayout({
    super.key,
    required this.mobileScaffold,
    required this.tabletScaffold,
    required this.dekstopScaffold,
  });

  Widget customScaffold() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded, // Warning icon
              color: Colors.red,
              size: 60.0, // Adjust the size as needed
            ),
            SizedBox(height: 20), // Spacing between the icon and text
            Text(
              'Please increase the height of the window',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold, // Make text bold
                fontSize: 18.0, // Adjust font size as needed
                color: Colors.black, // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          if (constraints.maxHeight < 550) {
            return customScaffold();
          }
          return mobileScaffold;
        } else if (constraints.maxWidth < 1100) {
          if (constraints.maxHeight < 600) {
            return customScaffold();
          }
          return tabletScaffold;
        } else {
          if (constraints.maxHeight < 650) {
            return customScaffold();
          }
          return dekstopScaffold;
        }
      },
    );
  }
}
