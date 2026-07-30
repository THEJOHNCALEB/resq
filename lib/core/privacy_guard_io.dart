import 'dart:io';
import 'privacy_monitor.dart';

void installNetworkGuard(PrivacyMonitor monitor) {
  HttpOverrides.global = _CountingHttpOverrides(monitor);
}

class _CountingHttpOverrides extends HttpOverrides {
  _CountingHttpOverrides(this.monitor);
  final PrivacyMonitor monitor;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _CountingHttpClient(super.createHttpClient(context), monitor);
}

class _CountingHttpClient implements HttpClient {
  _CountingHttpClient(this._inner, this._monitor);
  final HttpClient _inner;
  final PrivacyMonitor _monitor;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    _monitor.record(url.host);
    return _inner.openUrl(method, url);
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    _monitor.record(host);
    return _inner.open(method, host, port, path);
  }

  @override Future<HttpClientRequest> getUrl(Uri url) => openUrl('get', url);
  @override Future<HttpClientRequest> postUrl(Uri url) => openUrl('post', url);
  @override Future<HttpClientRequest> putUrl(Uri url) => openUrl('put', url);
  @override Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('delete', url);
  @override Future<HttpClientRequest> patchUrl(Uri url) => openUrl('patch', url);
  @override Future<HttpClientRequest> headUrl(Uri url) => openUrl('head', url);
  @override Future<HttpClientRequest> get(String host, int port, String path) => open('get', host, port, path);
  @override Future<HttpClientRequest> post(String host, int port, String path) => open('post', host, port, path);
  @override Future<HttpClientRequest> put(String host, int port, String path) => open('put', host, port, path);
  @override Future<HttpClientRequest> delete(String host, int port, String path) => open('delete', host, port, path);
  @override Future<HttpClientRequest> patch(String host, int port, String path) => open('patch', host, port, path);
  @override Future<HttpClientRequest> head(String host, int port, String path) => open('head', host, port, path);

  @override void addCredentials(Uri url, String realm, HttpClientCredentials c) => _inner.addCredentials(url, realm, c);
  @override void addProxyCredentials(String h, int p, String r, HttpClientCredentials c) => _inner.addProxyCredentials(h, p, r, c);
  @override void close({bool force = false}) => _inner.close(force: force);
  @override set connectionFactory(f) => _inner.connectionFactory = f;
  @override set authenticate(f) => _inner.authenticate = f;
  @override set authenticateProxy(f) => _inner.authenticateProxy = f;
  @override set findProxy(f) => _inner.findProxy = f;
  @override set badCertificateCallback(f) => _inner.badCertificateCallback = f;
  @override set keyLog(f) => _inner.keyLog = f;
  @override bool get autoUncompress => _inner.autoUncompress;
  @override set autoUncompress(bool v) => _inner.autoUncompress = v;
  @override Duration? get connectionTimeout => _inner.connectionTimeout;
  @override set connectionTimeout(Duration? v) => _inner.connectionTimeout = v;
  @override Duration get idleTimeout => _inner.idleTimeout;
  @override set idleTimeout(Duration v) => _inner.idleTimeout = v;
  @override int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override set maxConnectionsPerHost(int? v) => _inner.maxConnectionsPerHost = v;
  @override String? get userAgent => _inner.userAgent;
  @override set userAgent(String? v) => _inner.userAgent = v;
}
