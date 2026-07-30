import 'package:flutter/foundation.dart';
import 'privacy_guard_stub.dart'
    if (dart.library.io) 'privacy_guard_io.dart'
    if (dart.library.js_interop) 'privacy_guard_web.dart';

class PrivacyMonitor extends ChangeNotifier {
  PrivacyMonitor._();
  static final PrivacyMonitor instance = PrivacyMonitor._();

  int _count = 0;
  final List<String> _hosts = [];

  int get count => _count;
  List<String> get hosts => List.unmodifiable(_hosts);
  bool get isClean => _count == 0;

  void record(String host) {
    _count++;
    _hosts.add(host);
    notifyListeners();
  }

  void install() => installNetworkGuard(this);
}
