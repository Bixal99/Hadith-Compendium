import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadith_iq/provider/hadith_details_notifier.dart';
import 'package:hadith_iq/provider/manage_projects_provider.dart';
import 'package:hadith_iq/provider/narrator_item_provider.dart';
import 'package:hadith_iq/provider/server_status_provider.dart';
import 'package:hadith_iq/responsive/desktop_scaffold.dart';
import 'package:hadith_iq/responsive/mobile_scaffold.dart';
import 'package:hadith_iq/responsive/responsive_layout.dart';
import 'package:hadith_iq/responsive/tablet_scaffold.dart';
import 'package:hadith_iq/theme/theme.dart';
import 'package:hadith_iq/util/gobals.dart';
import 'package:hadith_iq/util/server_status_listener.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

void main() {

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Catch all Flutter framework errors (UI thread)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("Flutter Error: ${details.exception}");
    };

    runApp(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ManageProjectsProvider()),
      ChangeNotifierProvider(create: (_) => NarratorProvider()),
      ChangeNotifierProvider(create: (_) => HadithDetailsProvider()),
      ChangeNotifierProvider(create: (_) => ServerStatusProvider()),
    ], child: const MyApp()));
  }, (error, stackTrace) {
    debugPrint("Uncaught async error: $error");
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isMaximized = false;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: _themeMode,
      home: ServerStatusListener(
        child: Scaffold(
          body: Stack(
            children: [
              ResponsiveLayout(
                mobileScaffold: const MobileScaffold(),
                tabletScaffold: TabletScaffold(onToggleTheme: _toggleTheme),
                dekstopScaffold: DesktopScaffold(onToggleTheme: _toggleTheme),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: WindowHeader(
                  isMaximized: _isMaximized,
                  onToggleMaximize: () async {
                    final isMax = await windowManager.isMaximized();
                    if (isMax) {
                      await windowManager.unmaximize();
                    } else {
                      await windowManager.maximize();
                    }
                    setState(() {
                      _isMaximized = !isMax;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WindowHeader extends StatelessWidget {
  final bool isMaximized;
  final VoidCallback onToggleMaximize;

  const WindowHeader({
    super.key,
    required this.isMaximized,
    required this.onToggleMaximize,
  });

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: 36,
        padding: const EdgeInsets.only(right: 0),
        color: Colors
            .transparent, // Transparent so you can still see the content under
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: 15,
            children: [
              _WindowButton(
                color: Theme.of(context).colorScheme.secondary,
                icon: Icons.remove,
                onPressed: () => windowManager.minimize(),
              ),
              _WindowButton(
                color: Theme.of(context).colorScheme.secondary,
                icon: isMaximized ? Iconsax.maximize_26 : Iconsax.maximize_21,
                onPressed: onToggleMaximize,
                iconSize: 12,
              ),
              _WindowButton(
                color: Theme.of(context).colorScheme.primary,
                icon: Icons.close,
                onPressed: () => windowManager.close(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;

  const _WindowButton({
    required this.color,
    required this.icon,
    required this.onPressed,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
        onPressed: onPressed,
        splashRadius: 16,
        tooltip: icon == Icons.close
            ? 'Close'
            : icon == Iconsax.maximize_21
                ? 'Maximize'
                : 'Minimize',
        constraints: const BoxConstraints(),
      ),
    );
  }
}
