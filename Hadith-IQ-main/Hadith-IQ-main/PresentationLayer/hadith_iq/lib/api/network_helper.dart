import 'package:hadith_iq/provider/server_status_provider.dart';
import 'package:hadith_iq/util/gobals.dart';
import 'package:provider/provider.dart';

bool isServerOnline() {
  final context = navigatorKey.currentContext;
  if (context == null) return false;

  return Provider.of<ServerStatusProvider>(context, listen: false).isOnline;
}
