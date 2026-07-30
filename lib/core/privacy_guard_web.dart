import 'dart:js_interop';
import 'privacy_monitor.dart';

@JS('window')
external JSObject get _window;

@JS('Reflect.get')
external JSAny? _reflectGet(JSObject target, JSString key);

@JS('Reflect.set')
external bool _reflectSet(JSObject target, JSString key, JSAny? value);

void installNetworkGuard(PrivacyMonitor monitor) {
  final originalFetch = _reflectGet(_window, 'fetch'.toJS);
  if (originalFetch != null) {
    JSAny? patched(JSAny? input, [JSAny? init]) {
      try {
        monitor.record(_hostOf(input));
      } catch (_) {}
      return (originalFetch as JSFunction).callAsFunction(_window, input, init);
    }
    _reflectSet(_window, 'fetch'.toJS, patched.toJS);
  }
}

String _hostOf(JSAny? input) {
  try {
    final s = (input as JSString?)?.toDart ?? '';
    return Uri.tryParse(s)?.host ?? 'unknown';
  } catch (_) {
    return 'unknown';
  }
}
