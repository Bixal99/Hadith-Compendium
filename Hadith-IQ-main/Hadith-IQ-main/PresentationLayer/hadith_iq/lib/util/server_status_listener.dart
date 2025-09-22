import 'package:flutter/material.dart';
import 'package:hadith_iq/components/my_snackbars.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../provider/server_status_provider.dart';

class ServerStatusListener extends StatefulWidget {
  final Widget child;
  const ServerStatusListener({super.key, required this.child});

  @override
  State<ServerStatusListener> createState() => _ServerStatusListenerState();
}

class _ServerStatusListenerState extends State<ServerStatusListener> {
  bool? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serverStatus = Provider.of<ServerStatusProvider>(context);
    _lastStatus = serverStatus.isOnline;
    serverStatus.addListener(_onStatusChanged);
  }

  void _onStatusChanged() {
    final serverStatus =
        Provider.of<ServerStatusProvider>(context, listen: false);
    final newStatus = serverStatus.isOnline;

    if (_lastStatus != newStatus) {
      _lastStatus = newStatus;
      if (newStatus) {
        SnackBarCollection().successSnackBar(
            context,
            "Server is online.",
            Icon(Iconsax.tick_square,
                color: Theme.of(context).colorScheme.onTertiary),
            true);
      } else {
        SnackBarCollection().errorSnackBar(
            context,
            'Server is offline.',
            Icon(Iconsax.danger5, color: Theme.of(context).colorScheme.onError),
            true);
      }
    }
  }

  @override
  void dispose() {
    Provider.of<ServerStatusProvider>(context, listen: false)
        .removeListener(_onStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
