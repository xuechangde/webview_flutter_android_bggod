// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AndroidViewSurface;

import 'android_webview.pigeon.dart';
import 'android_webview_api_impls.dart';

/// An Android View that displays web pages.
///
/// **Basic usage**
/// In most cases, we recommend using a standard web browser, like Chrome, to
/// deliver content to the user. To learn more about web browsers, read the
/// guide on invoking a browser with
/// [url_launcher](https://pub.dev/packages/url_launcher).
///
/// WebView objects allow you to display web content as part of your widget
/// layout, but lack some of the features of fully-developed browsers. A WebView
/// is useful when you need increased control over the UI and advanced
/// configuration options that will allow you to embed web pages in a
/// specially-designed environment for your app.
///
/// To learn more about WebView and alternatives for serving web content, read
/// the documentation on
/// [Web-based content](https://developer.android.com/guide/webapps).
///
/// When a [WebView] is no longer needed [release] must be called.
class WebView {
  /// Constructs a new WebView.
  WebView({this.useHybridComposition = false}) {
    api.createFromInstance(this);
  }

  /// Pigeon Host Api implementation for [WebView].
  @visibleForTesting
  static WebViewHostApiImpl api = WebViewHostApiImpl();

  WebViewClient? _currentWebViewClient;

  /// Whether the [WebView] will be rendered with an [AndroidViewSurface].
  ///
  /// This implementation uses hybrid composition to render the WebView Widget.
  /// This comes at the cost of some performance on Android versions below 10.
  /// See
  /// https://flutter.dev/docs/development/platform-integration/platform-views#performance
  /// for more information.
  ///
  /// Defaults to false.
  final bool useHybridComposition;

  /// The [WebSettings] object used to control the settings for this WebView.
  late final WebSettings settings = WebSettings(this);

  /// Enables debugging of web contents (HTML / CSS / JavaScript) loaded into any WebViews of this application.
  ///
  /// This flag can be enabled in order to facilitate debugging of web layouts
  /// and JavaScript code running inside WebViews. Please refer to [WebView]
  /// documentation for the debugging guide. The default is false.
  static Future<void> setWebContentsDebuggingEnabled(bool enabled) {
    return api.setWebContentsDebuggingEnabled(enabled);
  }

  /// Loads the given data into this WebView using a 'data' scheme URL.
  ///
  /// Note that JavaScript's same origin policy means that script running in a
  /// page loaded using this method will be unable to access content loaded
  /// using any scheme other than 'data', including 'http(s)'. To avoid this
  /// restriction, use [loadDataWithBaseURL()] with an appropriate base URL.
  ///
  /// The [encoding] parameter specifies whether the data is base64 or URL
  /// encoded. If the data is base64 encoded, the value of the encoding
  /// parameter must be `'base64'`. HTML can be encoded with
  /// `base64.encode(bytes)` like so:
  /// ```dart
  /// import 'dart:convert';
  ///
  /// final unencodedHtml = '''
  ///   <html><body>'%28' is the code for '('</body></html>
  /// ''';
  /// final encodedHtml = base64.encode(utf8.encode(unencodedHtml));
  /// print(encodedHtml);
  /// ```
  ///
  /// The [mimeType] parameter specifies the format of the data. If WebView
  /// can't handle the specified MIME type, it will download the data. If
  /// `null`, defaults to 'text/html'.
  Future<void> loadData({
    required String data,
    String? mimeType,
    String? encoding,
  }) {
    return api.loadDataFromInstance(
      this,
      data,
      mimeType,
      encoding,
    );
  }

  /// Loads the given data into this WebView.
  ///
  /// The [baseUrl] is used as base URL for the content. It is used  both to
  /// resolve relative URLs and when applying JavaScript's same origin policy.
  ///
  /// The [historyUrl] is used for the history entry.
  ///
  /// The [mimeType] parameter specifies the format of the data. If WebView
  /// can't handle the specified MIME type, it will download the data. If
  /// `null`, defaults to 'text/html'.
  ///
  /// Note that content specified in this way can access local device files (via
  /// 'file' scheme URLs) only if baseUrl specifies a scheme other than 'http',
  /// 'https', 'ftp', 'ftps', 'about' or 'javascript'.
  ///
  /// If the base URL uses the data scheme, this method is equivalent to calling
  /// [loadData] and the [historyUrl] is ignored, and the data will be treated
  /// as part of a data: URL, including the requirement that the content be
  /// URL-encoded or base64 encoded. If the base URL uses any other scheme, then
  /// the data will be loaded into the WebView as a plain string (i.e. not part
  /// of a data URL) and any URL-encoded entities in the string will not be
  /// decoded.
  ///
  /// Note that the [baseUrl] is sent in the 'Referer' HTTP header when
  /// requesting subresources (images, etc.) of the page loaded using this
  /// method.
  ///
  /// If a valid HTTP or HTTPS base URL is not specified in [baseUrl], then
  /// content loaded using this method will have a `window.origin` value of
  /// `"null"`. This must not be considered to be a trusted origin by the
  /// application or by any JavaScript code running inside the WebView (for
  /// example, event sources in DOM event handlers or web messages), because
  /// malicious content can also create frames with a null origin. If you need
  /// to identify the main frame's origin in a trustworthy way, you should use a
  /// valid HTTP or HTTPS base URL to set the origin.
  Future<void> loadDataWithBaseUrl({
    String? baseUrl,
    required String data,
    String? mimeType,
    String? encoding,
    String? historyUrl,
  }) {
    return api.loadDataWithBaseUrlFromInstance(
      this,
      baseUrl,
      data,
      mimeType,
      encoding,
      historyUrl,
    );
  }

  /// Loads the given URL with additional HTTP headers, specified as a map from name to value.
  ///
  /// Note that if this map contains any of the headers that are set by default
  /// by this WebView, such as those controlling caching, accept types or the
  /// User-Agent, their values may be overridden by this WebView's defaults.
  ///
  /// Also see compatibility note on [evaluateJavascript].
  Future<void> loadUrl(String url, Map<String, String> headers) {
    return api.loadUrlFromInstance(this, url, headers);
  }

  /// Loads the URL with postData using "POST" method into this WebView.
  ///
  /// If url is not a network URL, it will be loaded with [loadUrl] instead, ignoring the postData param.
  Future<void> postUrl(String url, Uint8List data) {
    return api.postUrlFromInstance(this, url, data);
  }

  /// Gets the URL for the current page.
  ///
  /// This is not always the same as the URL passed to
  /// [WebViewClient.onPageStarted] because although the load for that URL has
  /// begun, the current page may not have changed.
  ///
  /// Returns null if no page has been loaded.
  Future<String?> getUrl() {
    return api.getUrlFromInstance(this);
  }

  /// Whether this WebView has a back history item.
  Future<bool> canGoBack() {
    return api.canGoBackFromInstance(this);
  }

  /// Whether this WebView has a forward history item.
  Future<bool> canGoForward() {
    return api.canGoForwardFromInstance(this);
  }

  /// Goes back in the history of this WebView.
  Future<void> goBack() {
    return api.goBackFromInstance(this);
  }

  /// Goes forward in the history of this WebView.
  Future<void> goForward() {
    return api.goForwardFromInstance(this);
  }

  /// Reloads the current URL.
  Future<void> reload() {
    return api.reloadFromInstance(this);
  }

  /// Clears the resource cache.
  ///
  /// Note that the cache is per-application, so this will clear the cache for
  /// all WebViews used.
  Future<void> clearCache(bool includeDiskFiles) {
    return api.clearCacheFromInstance(this, includeDiskFiles);
  }

  // TODO(bparrishMines): Update documentation once addJavascriptInterface is added.
  /// Asynchronously evaluates JavaScript in the context of the currently displayed page.
  ///
  /// If non-null, the returned value will be any result returned from that
  /// execution.
  ///
  /// Compatibility note. Applications targeting Android versions N or later,
  /// JavaScript state from an empty WebView is no longer persisted across
  /// navigations like [loadUrl]. For example, global variables and functions
  /// defined before calling [loadUrl]) will not exist in the loaded page.
  Future<String?> evaluateJavascript(String javascriptString) {
    return api.evaluateJavascriptFromInstance(
      this,
      javascriptString,
    );
  }

  // TODO(bparrishMines): Update documentation when WebViewClient.onReceivedTitle is added.
  /// Gets the title for the current page.
  ///
  /// Returns null if no page has been loaded.
  Future<String?> getTitle() {
    return api.getTitleFromInstance(this);
  }

  // TODO(bparrishMines): Update documentation when onScrollChanged is added.
  /// Set the scrolled position of your view.
  Future<void> scrollTo(int x, int y) {
    return api.scrollToFromInstance(this, x, y);
  }

  // TODO(bparrishMines): Update documentation when onScrollChanged is added.
  /// Move the scrolled position of your view.
  Future<void> scrollBy(int x, int y) {
    return api.scrollByFromInstance(this, x, y);
  }

  /// Return the scrolled left position of this view.
  ///
  /// This is the left edge of the displayed part of your view. You do not
  /// need to draw any pixels farther left, since those are outside of the frame
  /// of your view on screen.
  Future<int> getScrollX() {
    return api.getScrollXFromInstance(this);
  }

  /// Return the scrolled top position of this view.
  ///
  /// This is the top edge of the displayed part of your view. You do not need
  /// to draw any pixels above it, since those are outside of the frame of your
  /// view on screen.
  Future<int> getScrollY() {
    return api.getScrollYFromInstance(this);
  }

  /// Sets the [WebViewClient] that will receive various notifications and requests.
  ///
  /// This will replace the current handler.
  Future<void> setWebViewClient(WebViewClient webViewClient) {
    _currentWebViewClient = webViewClient;
    WebViewClient.api.createFromInstance(webViewClient);
    return api.setWebViewClientFromInstance(this, webViewClient);
  }

  /// Injects the supplied [JavascriptChannel] into this WebView.
  ///
  /// The object is injected into all frames of the web page, including all the
  /// iframes, using the supplied name. This allows the object's methods to
  /// be accessed from JavaScript.
  ///
  /// Note that injected objects will not appear in JavaScript until the page is
  /// next (re)loaded. JavaScript should be enabled before injecting the object.
  /// For example:
  ///
  /// ```dart
  /// webview.settings.setJavaScriptEnabled(true);
  /// webView.addJavascriptChannel(JavScriptChannel("injectedObject"));
  /// webView.loadUrl("about:blank", <String, String>{});
  /// webView.loadUrl("javascript:injectedObject.postMessage("Hello, World!")", <String, String>{});
  /// ```
  ///
  /// **Important**
  /// * Because the object is exposed to all the frames, any frame could obtain
  /// the object name and call methods on it. There is no way to tell the
  /// calling frame's origin from the app side, so the app must not assume that
  /// the caller is trustworthy unless the app can guarantee that no third party
  /// content is ever loaded into the WebView even inside an iframe.
  Future<void> addJavaScriptChannel(JavaScriptChannel javaScriptChannel) {
    JavaScriptChannel.api.createFromInstance(javaScriptChannel);
    return api.addJavaScriptChannelFromInstance(this, javaScriptChannel);
  }

  /// Removes a previously injected [JavaScriptChannel] from this WebView.
  ///
  /// Note that the removal will not be reflected in JavaScript until the page
  /// is next (re)loaded. See [addJavaScriptChannel].
  Future<void> removeJavaScriptChannel(JavaScriptChannel javaScriptChannel) {
    JavaScriptChannel.api.createFromInstance(javaScriptChannel);
    return api.removeJavaScriptChannelFromInstance(this, javaScriptChannel);
  }

  /// Registers the interface to be used when content can not be handled by the rendering engine, and should be downloaded instead.
  ///
  /// This will replace the current handler.
  Future<void> setDownloadListener(DownloadListener? listener) async {
    await Future.wait(<Future<void>>[
      if (listener != null) DownloadListener.api.createFromInstance(listener),
      api.setDownloadListenerFromInstance(this, listener)
    ]);
  }

  /// Sets the chrome handler.
  ///
  /// This is an implementation of [WebChromeClient] for use in handling
  /// JavaScript dialogs, favicons, titles, and the progress. This will replace
  /// the current handler.
  Future<void> setWebChromeClient(WebChromeClient? client) async {
    // WebView requires a WebViewClient because of a bug fix that makes
    // calls to WebViewClient.requestLoading/WebViewClient.urlLoading when a new
    // window is opened. This is to make sure a url opened by `Window.open` has
    // a secure url.
    assert(
      _currentWebViewClient != null,
      "Can't set a WebChromeClient without setting a WebViewClient first.",
    );
    await Future.wait(<Future<void>>[
      if (client != null)
        WebChromeClient.api.createFromInstance(client, _currentWebViewClient!),
      api.setWebChromeClientFromInstance(this, client),
    ]);
  }

  /// Sets the background color of this WebView.
  Future<void> setBackgroundColor(Color color) {
    return api.setBackgroundColorFromInstance(this, color.value);
  }

  /// Releases all resources used by the [WebView].
  ///
  /// Any methods called after [release] will throw an exception.
  Future<void> release() {
    _currentWebViewClient = null;
    WebSettings.api.disposeFromInstance(settings);
    return api.disposeFromInstance(this);
  }
}

/// Manages cookies globally for all webviews.
class CookieManager {
  CookieManager._();

  static CookieManager? _instance;

  /// Gets the globally set CookieManager instance.
  static CookieManager get instance => _instance ??= CookieManager._();

  /// Setter for the singleton value, for testing purposes only.
  @visibleForTesting
  static set instance(CookieManager value) => _instance = value;

  /// Pigeon Host Api implementation for [CookieManager].
  @visibleForTesting
  static CookieManagerHostApi api = CookieManagerHostApi();

  /// Sets a single cookie (key-value pair) for the given URL. Any existing
  /// cookie with the same host, path and name will be replaced with the new
  /// cookie. The cookie being set will be ignored if it is expired. To set
  /// multiple cookies, your application should invoke this method multiple
  /// times.
  ///
  /// The value parameter must follow the format of the Set-Cookie HTTP
  /// response header defined by RFC6265bis. This is a key-value pair of the
  /// form "key=value", optionally followed by a list of cookie attributes
  /// delimited with semicolons (ex. "key=value; Max-Age=123"). Please consult
  /// the RFC specification for a list of valid attributes.
  ///
  /// Note: if specifying a value containing the "Secure" attribute, url must
  /// use the "https://" scheme.
  ///
  /// Params:
  /// url – the URL for which the cookie is to be set
  /// value – the cookie as a string, using the format of the 'Set-Cookie' HTTP response header
  Future<void> setCookie(String url, String value) => api.setCookie(url, value);

  /// Removes all cookies.
  ///
  /// The returned future resolves to true if any cookies were removed.
  Future<bool> clearCookies() => api.clearCookies();
}

/// Manages settings state for a [WebView].
///
/// When a WebView is first created, it obtains a set of default settings. These
/// default settings will be returned from any getter call. A WebSettings object
/// obtained from [WebView.settings] is tied to the life of the WebView. If a
/// WebView has been destroyed, any method call on [WebSettings] will throw an
/// Exception.
class WebSettings {
  /// Constructs a [WebSettings].
  ///
  /// This constructor is only used for testing. An instance should be obtained
  /// with [WebView.settings].
  @visibleForTesting
  WebSettings(WebView webView) {
    api.createFromInstance(this, webView);
  }

  /// Pigeon Host Api implementation for [WebSettings].
  @visibleForTesting
  static WebSettingsHostApiImpl api = WebSettingsHostApiImpl();

  /// Sets whether the DOM storage API is enabled.
  ///
  /// The default value is false.
  Future<void> setDomStorageEnabled(bool flag) {
    return api.setDomStorageEnabledFromInstance(this, flag);
  }

  /// Tells JavaScript to open windows automatically.
  ///
  /// This applies to the JavaScript function `window.open()`. The default is
  /// false.
  Future<void> setJavaScriptCanOpenWindowsAutomatically(bool flag) {
    return api.setJavaScriptCanOpenWindowsAutomaticallyFromInstance(
      this,
      flag,
    );
  }

  // TODO(bparrishMines): Update documentation when WebChromeClient.onCreateWindow is added.
  /// Sets whether the WebView should supports multiple windows.
  ///
  /// The default is false.
  Future<void> setSupportMultipleWindows(bool support) {
    return api.setSupportMultipleWindowsFromInstance(this, support);
  }

  /// Tells the WebView to enable JavaScript execution.
  ///
  /// The default is false.
  Future<void> setJavaScriptEnabled(bool flag) {
    return api.setJavaScriptEnabledFromInstance(this, flag);
  }

  /// Sets the WebView's user-agent string.
  ///
  /// If the string is empty, the system default value will be used. Note that
  /// starting from KITKAT Android version, changing the user-agent while
  /// loading a web page causes WebView to initiate loading once again.
  Future<void> setUserAgentString(String? userAgentString) {
    return api.setUserAgentStringFromInstance(this, userAgentString);
  }

  /// Sets whether the WebView requires a user gesture to play media.
  ///
  /// The default is true.
  Future<void> setMediaPlaybackRequiresUserGesture(bool require) {
    return api.setMediaPlaybackRequiresUserGestureFromInstance(this, require);
  }

  // TODO(bparrishMines): Update documentation when WebView.zoomIn and WebView.zoomOut are added.
  /// Sets whether the WebView should support zooming using its on-screen zoom controls and gestures.
  ///
  /// The particular zoom mechanisms that should be used can be set with
  /// [setBuiltInZoomControls].
  ///
  /// The default is true.
  Future<void> setSupportZoom(bool support) {
    return api.setSupportZoomFromInstance(this, support);
  }

  /// Sets whether the WebView loads pages in overview mode, that is, zooms out the content to fit on screen by width.
  ///
  /// This setting is taken into account when the content width is greater than
  /// the width of the WebView control, for example, when [setUseWideViewPort]
  /// is enabled.
  ///
  /// The default is false.
  Future<void> setLoadWithOverviewMode(bool overview) {
    return api.setLoadWithOverviewModeFromInstance(this, overview);
  }

  /// Sets whether the WebView should enable support for the "viewport" HTML meta tag or should use a wide viewport.
  ///
  /// When the value of the setting is false, the layout width is always set to
  /// the width of the WebView control in device-independent (CSS) pixels. When
  /// the value is true and the page contains the viewport meta tag, the value
  /// of the width specified in the tag is used. If the page does not contain
  /// the tag or does not provide a width, then a wide viewport will be used.
  Future<void> setUseWideViewPort(bool use) {
    return api.setUseWideViewPortFromInstance(this, use);
  }

  // TODO(bparrishMines): Update documentation when ZoomButtonsController is added.
  /// Sets whether the WebView should display on-screen zoom controls when using the built-in zoom mechanisms.
  ///
  /// See [setBuiltInZoomControls]. The default is true. However, on-screen zoom
  /// controls are deprecated in Android so it's recommended to set this to
  /// false.
  Future<void> setDisplayZoomControls(bool enabled) {
    return api.setDisplayZoomControlsFromInstance(this, enabled);
  }

  // TODO(bparrishMines): Update documentation when ZoomButtonsController is added.
  /// Sets whether the WebView should use its built-in zoom mechanisms.
  ///
  /// The built-in zoom mechanisms comprise on-screen zoom controls, which are
  /// displayed over the WebView's content, and the use of a pinch gesture to
  /// control zooming. Whether or not these on-screen controls are displayed can
  /// be set with [setDisplayZoomControls]. The default is false.
  ///
  /// The built-in mechanisms are the only currently supported zoom mechanisms,
  /// so it is recommended that this setting is always enabled. However,
  /// on-screen zoom controls are deprecated in Android so it's recommended to
  /// disable [setDisplayZoomControls].
  Future<void> setBuiltInZoomControls(bool enabled) {
    return api.setBuiltInZoomControlsFromInstance(this, enabled);
  }

  /// Enables or disables file access within WebView.
  ///
  /// This enables or disables file system access only. Assets and resources are
  /// still accessible using file:///android_asset and file:///android_res. The
  /// default value is true for apps targeting Build.VERSION_CODES.Q and below,
  /// and false when targeting Build.VERSION_CODES.R and above.
  Future<void> setAllowFileAccess(bool enabled) {
    return api.setAllowFileAccessFromInstance(this, enabled);
  }
}

/// Exposes a channel to receive calls from javaScript.
///
/// See [WebView.addJavaScriptChannel].
abstract class JavaScriptChannel {
  /// Constructs a [JavaScriptChannel].
  JavaScriptChannel(this.channelName) {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
  }

  /// Pigeon Host Api implementation for [JavaScriptChannel].
  @visibleForTesting
  static JavaScriptChannelHostApiImpl api = JavaScriptChannelHostApiImpl();

  /// Used to identify this object to receive messages from javaScript.
  final String channelName;

  /// Callback method when javaScript calls `postMessage` on the object instance passed.
  void postMessage(String message);
}

/// Receive various notifications and requests for [WebView].
abstract class WebViewClient {
  /// Constructs a [WebViewClient].
  WebViewClient({this.shouldOverrideUrlLoading = true}) {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
  }

  /// User authentication failed on server.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_AUTHENTICATION
  static const int errorAuthentication = -4;

  /// Malformed URL.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_BAD_URL
  static const int errorBadUrl = -12;

  /// Failed to connect to the server.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_CONNECT
  static const int errorConnect = -6;

  /// Failed to perform SSL handshake.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_FAILED_SSL_HANDSHAKE
  static const int errorFailedSslHandshake = -11;

  /// Generic file error.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_FILE
  static const int errorFile = -13;

  /// File not found.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_FILE_NOT_FOUND
  static const int errorFileNotFound = -14;

  /// Server or proxy hostname lookup failed.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_HOST_LOOKUP
  static const int errorHostLookup = -2;

  /// Failed to read or write to the server.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_IO
  static const int errorIO = -7;

  /// User authentication failed on proxy.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_PROXY_AUTHENTICATION
  static const int errorProxyAuthentication = -5;

  /// Too many redirects.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_REDIRECT_LOOP
  static const int errorRedirectLoop = -9;

  /// Connection timed out.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_TIMEOUT
  static const int errorTimeout = -8;

  /// Too many requests during this load.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_TOO_MANY_REQUESTS
  static const int errorTooManyRequests = -15;

  /// Generic error.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNKNOWN
  static const int errorUnknown = -1;

  /// Resource load was canceled by Safe Browsing.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNSAFE_RESOURCE
  static const int errorUnsafeResource = -16;

  /// Unsupported authentication scheme (not basic or digest).
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNSUPPORTED_AUTH_SCHEME
  static const int errorUnsupportedAuthScheme = -3;

  /// Unsupported URI scheme.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebViewClient#ERROR_UNSUPPORTED_SCHEME
  static const int errorUnsupportedScheme = -10;

  /// Pigeon Host Api implementation for [WebViewClient].
  @visibleForTesting
  static WebViewClientHostApiImpl api = WebViewClientHostApiImpl();

  /// Whether loading a url should be overridden.
  ///
  /// In Java, `shouldOverrideUrlLoading()` and `shouldOverrideRequestLoading()`
  /// callbacks must synchronously return a boolean. This sets the default
  /// return value.
  ///
  /// Setting [shouldOverrideUrlLoading] to true causes the current [WebView] to
  /// abort loading the URL, while returning false causes the [WebView] to
  /// continue loading the URL as usual. [requestLoading] or [urlLoading] will
  /// still be called either way.
  ///
  /// Defaults to true.
  final bool shouldOverrideUrlLoading;

  /// Notify the host application that a page has started loading.
  ///
  /// This method is called once for each main frame load so a page with iframes
  /// or framesets will call onPageStarted one time for the main frame. This
  /// also means that [onPageStarted] will not be called when the contents of an
  /// embedded frame changes, i.e. clicking a link whose target is an iframe, it
  /// will also not be called for fragment navigations (navigations to
  /// #fragment_id).
  void onPageStarted(WebView webView, String url) {}

  // TODO(bparrishMines): Update documentation when WebView.postVisualStateCallback is added.
  /// Notify the host application that a page has finished loading.
  ///
  /// This method is called only for main frame. Receiving an [onPageFinished]
  /// callback does not guarantee that the next frame drawn by WebView will
  /// reflect the state of the DOM at this point.
  void onPageFinished(WebView webView, String url) {}

  /// Report web resource loading error to the host application.
  ///
  /// These errors usually indicate inability to connect to the server. Note
  /// that unlike the deprecated version of the callback, the new version will
  /// be called for any resource (iframe, image, etc.), not just for the main
  /// page. Thus, it is recommended to perform minimum required work in this
  /// callback.
  void onReceivedRequestError(
    WebView webView,
    WebResourceRequest request,
    WebResourceError error,
  ) {}

  /// Report an error to the host application.
  ///
  /// These errors are unrecoverable (i.e. the main resource is unavailable).
  /// The errorCode parameter corresponds to one of the error* constants.
  @Deprecated('Only called on Android version < 23.')
  void onReceivedError(
    WebView webView,
    int errorCode,
    String description,
    String failingUrl,
  ) {}

  // TODO(bparrishMines): Update documentation once synchronous url handling is supported.
  /// When a URL is about to be loaded in the current [WebView].
  ///
  /// If a [WebViewClient] is not provided, by default [WebView] will ask
  /// Activity Manager to choose the proper handler for the URL. If a
  /// [WebViewClient] is provided, setting [shouldOverrideUrlLoading] to true
  /// causes the current [WebView] to abort loading the URL, while returning
  /// false causes the [WebView] to continue loading the URL as usual.
  void requestLoading(WebView webView, WebResourceRequest request) {}

  // TODO(bparrishMines): Update documentation once synchronous url handling is supported.
  /// When a URL is about to be loaded in the current [WebView].
  ///
  /// If a [WebViewClient] is not provided, by default [WebView] will ask
  /// Activity Manager to choose the proper handler for the URL. If a
  /// [WebViewClient] is provided, setting [shouldOverrideUrlLoading] to true
  /// causes the current [WebView] to abort loading the URL, while returning
  /// false causes the [WebView] to continue loading the URL as usual.
  void urlLoading(WebView webView, String url) {}
}

/// The interface to be used when content can not be handled by the rendering engine for [WebView], and should be downloaded instead.
abstract class DownloadListener {
  /// Constructs a [DownloadListener].
  DownloadListener() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
  }

  /// Pigeon Host Api implementation for [DownloadListener].
  @visibleForTesting
  static DownloadListenerHostApiImpl api = DownloadListenerHostApiImpl();

  /// Notify the host application that a file should be downloaded.
  void onDownloadStart(
    String url,
    String userAgent,
    String contentDisposition,
    String mimetype,
    int contentLength,
  );
}

/// Handles JavaScript dialogs, favicons, titles, and the progress for [WebView].
abstract class WebChromeClient {
  /// Constructs a [WebChromeClient].
  WebChromeClient() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
  }

  /// Pigeon Host Api implementation for [WebChromeClient].
  @visibleForTesting
  static WebChromeClientHostApiImpl api = WebChromeClientHostApiImpl();

  /// Notify the host application that a file should be downloaded.
  void onProgressChanged(WebView webView, int progress) {}
}

/// Encompasses parameters to the [WebViewClient.requestLoading] method.
class WebResourceRequest {
  /// Constructs a [WebResourceRequest].
  WebResourceRequest({
    required this.url,
    required this.isForMainFrame,
    required this.isRedirect,
    required this.hasGesture,
    required this.method,
    required this.requestHeaders,
  });

  /// The URL for which the resource request was made.
  final String url;

  /// Whether the request was made in order to fetch the main frame's document.
  final bool isForMainFrame;

  /// Whether the request was a result of a server-side redirect.
  ///
  /// Only supported on Android version >= 24.
  final bool? isRedirect;

  /// Whether a gesture (such as a click) was associated with the request.
  final bool hasGesture;

  /// The method associated with the request, for example "GET".
  final String method;

  /// The headers associated with the request.
  final Map<String, String> requestHeaders;
}

/// Encapsulates information about errors occurred during loading of web resources.
///
/// See [WebViewClient.onReceivedRequestError].
class WebResourceError {
  /// Constructs a [WebResourceError].
  WebResourceError({
    required this.errorCode,
    required this.description,
  });

  /// The integer code of the error (e.g. [WebViewClient.errorAuthentication].
  final int errorCode;

  /// Describes the error.
  final String description;
}

/// Manages Flutter assets that are part of Android's app bundle.
class FlutterAssetManager {
  /// Constructs the [FlutterAssetManager].
  const FlutterAssetManager();

  /// Pigeon Host Api implementation for [FlutterAssetManager].
  @visibleForTesting
  static FlutterAssetManagerHostApi api = FlutterAssetManagerHostApi();

  /// Lists all assets at the given path.
  ///
  /// The assets are returned as a `List<String>`. The `List<String>` only
  /// contains files which are direct childs
  Future<List<String?>> list(String path) => api.list(path);

  /// Gets the relative file path to the Flutter asset with the given name.
  Future<String> getAssetFilePathByName(String name) =>
      api.getAssetFilePathByName(name);
}

/// Manages the JavaScript storage APIs provided by the [WebView].
///
/// Wraps [WebStorage](https://developer.android.com/reference/android/webkit/WebStorage).
class WebStorage {
  /// Constructs a [WebStorage].
  ///
  /// This constructor is only used for testing. An instance should be obtained
  /// with [WebStorage.instance].
  @visibleForTesting
  WebStorage() {
    AndroidWebViewFlutterApis.instance.ensureSetUp();
    api.createFromInstance(this);
  }

  /// Pigeon Host Api implementation for [WebStorage].
  @visibleForTesting
  static WebStorageHostApiImpl api = WebStorageHostApiImpl();

  /// The singleton instance of this class.
  static WebStorage instance = WebStorage();

  /// Clears all storage currently being used by the JavaScript storage APIs.
  Future<void> deleteAllData() {
    return api.deleteAllDataFromInstance(this);
  }
}
