import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MobileScaffold extends StatefulWidget {
  const MobileScaffold({super.key});

  @override
  State<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends State<MobileScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // logo in background
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topLeft, // Display the top-left portion
                  widthFactor:
                      0.65, // Adjust to show a portion horizontally (percentage)
                  heightFactor:
                      0.73, // Adjust to show a portion vertically (percentage)
                  child: Opacity(
                    opacity: 0.07, // Adjust opacity
                    child: Image.asset(
                      'assets/images/FYP_Logo.png',
                      fit: BoxFit.cover,
                      width: 750, // Original image width
                      height: 450, // Original image height
                    ),
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Mobile Version",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ).merge(GoogleFonts.elMessiri()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 82,),
                    Text(
                      "Coming Soon...",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ).merge(GoogleFonts.elMessiri()),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
