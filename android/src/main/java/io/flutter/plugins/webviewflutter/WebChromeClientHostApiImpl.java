// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import static android.app.Activity.RESULT_OK;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Message;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import android.util.Log;
import android.webkit.GeolocationPermissions;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import androidx.core.content.FileProvider;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import io.flutter.app.FlutterApplication;
import io.flutter.plugins.webviewflutter.GeneratedAndroidWebView.WebChromeClientHostApi;

/**
 * Host api implementation for {@link WebChromeClient}.
 *
 * <p>Handles creating {@link WebChromeClient}s that intercommunicate with a paired Dart object.
 */
public class WebChromeClientHostApiImpl implements WebChromeClientHostApi {
  private final InstanceManager instanceManager;
  private final WebChromeClientCreator webChromeClientCreator;
  private final WebChromeClientFlutterApiImpl flutterApi;

  private static ValueCallback<Uri> mUploadMessage;
  private static ValueCallback<Uri[]> mUploadMessageArray;
  private final static int FILECHOOSER_RESULTCODE = 1;
  private static Uri fileUri;
  private static Uri videoUri;
  public ResultHandler resultHandler = new ResultHandler();

  /**
   * Implementation of {@link WebChromeClient} that passes arguments of callback methods to Dart.
   */
  public static class WebChromeClientImpl extends WebChromeClient implements Releasable {
    @Nullable private WebChromeClientFlutterApiImpl flutterApi;
    private WebViewClient webViewClient;

    /**
     * Creates a {@link WebChromeClient} that passes arguments of callbacks methods to Dart.
     *
     * @param flutterApi handles sending messages to Dart
     * @param webViewClient receives forwarded calls from {@link WebChromeClient#onCreateWindow}
     */
    public WebChromeClientImpl(
        @NonNull WebChromeClientFlutterApiImpl flutterApi, WebViewClient webViewClient) {
      this.flutterApi = flutterApi;
      this.webViewClient = webViewClient;
    }

    @Override
    public boolean onCreateWindow(
        final WebView view, boolean isDialog, boolean isUserGesture, Message resultMsg) {
      return onCreateWindow(view, resultMsg, new WebView(view.getContext()));
    }

    /**
     * Verifies that a url opened by `Window.open` has a secure url.
     *
     * @param view the WebView from which the request for a new window originated.
     * @param resultMsg the message to send when once a new WebView has been created. resultMsg.obj
     *     is a {@link WebView.WebViewTransport} object. This should be used to transport the new
     *     WebView, by calling WebView.WebViewTransport.setWebView(WebView)
     * @param onCreateWindowWebView the temporary WebView used to verify the url is secure
     * @return this method should return true if the host application will create a new window, in
     *     which case resultMsg should be sent to its target. Otherwise, this method should return
     *     false. Returning false from this method but also sending resultMsg will result in
     *     undefined behavior
     */
    @VisibleForTesting
    boolean onCreateWindow(
        final WebView view, Message resultMsg, @Nullable WebView onCreateWindowWebView) {
      final WebViewClient windowWebViewClient =
          new WebViewClient() {
            @RequiresApi(api = Build.VERSION_CODES.N)
            @Override
            public boolean shouldOverrideUrlLoading(
                @NonNull WebView windowWebView, @NonNull WebResourceRequest request) {
              if (!webViewClient.shouldOverrideUrlLoading(view, request)) {
                view.loadUrl(request.getUrl().toString());
              }
              return true;
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView windowWebView, String url) {
              if (!webViewClient.shouldOverrideUrlLoading(view, url)) {
                view.loadUrl(url);
              }
              return true;
            }
          };

      if (onCreateWindowWebView == null) {
        onCreateWindowWebView = new WebView(view.getContext());
      }
      onCreateWindowWebView.setWebViewClient(windowWebViewClient);

      final WebView.WebViewTransport transport = (WebView.WebViewTransport) resultMsg.obj;
      transport.setWebView(onCreateWindowWebView);
      resultMsg.sendToTarget();

      return true;
    }

    //For Android 5.0+
    public boolean onShowFileChooser(
            WebView webView, ValueCallback<Uri[]> filePathCallback,
            FileChooserParams fileChooserParams) {
      if (mUploadMessageArray != null) {
        mUploadMessageArray.onReceiveValue(null);
      }
      mUploadMessageArray = filePathCallback;

      final String[] acceptTypes = getSafeAcceptedTypes(fileChooserParams);
      List<Intent> intentList = new ArrayList<Intent>();
      fileUri = null;
      videoUri = null;
      if (acceptsImages(acceptTypes)) {
        Intent takePhotoIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        fileUri = getOutputFilename(MediaStore.ACTION_IMAGE_CAPTURE);
        takePhotoIntent.putExtra(MediaStore.EXTRA_OUTPUT, fileUri);
        intentList.add(takePhotoIntent);
      }
      if (acceptsVideo(acceptTypes)) {
        Intent takeVideoIntent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);
        videoUri = getOutputFilename(MediaStore.ACTION_VIDEO_CAPTURE);
        takeVideoIntent.putExtra(MediaStore.EXTRA_OUTPUT, videoUri);
        intentList.add(takeVideoIntent);
      }
      Intent contentSelectionIntent;
      if (Build.VERSION.SDK_INT >= 21) {
        final boolean allowMultiple = fileChooserParams.getMode() == FileChooserParams.MODE_OPEN_MULTIPLE;
        contentSelectionIntent = fileChooserParams.createIntent();
        contentSelectionIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple);
      } else {
        contentSelectionIntent = new Intent(Intent.ACTION_GET_CONTENT);
        contentSelectionIntent.addCategory(Intent.CATEGORY_OPENABLE);
        contentSelectionIntent.setType("*/*");
      }
      Intent[] intentArray = intentList.toArray(new Intent[intentList.size()]);

      Intent chooserIntent = new Intent(Intent.ACTION_CHOOSER);
      chooserIntent.putExtra(Intent.EXTRA_INTENT, contentSelectionIntent);
      chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, intentArray);
      WebViewFlutterPlugin.activity.startActivityForResult(chooserIntent, FILECHOOSER_RESULTCODE);
      return true;
    }

    public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
      callback.invoke(origin, true, false);
    }

    @Override
    public void onProgressChanged(WebView view, int progress) {
      if (flutterApi != null) {
        flutterApi.onProgressChanged(this, view, (long) progress, reply -> {});
      }
    }

    /**
     * Set the {@link WebViewClient} that calls to {@link WebChromeClient#onCreateWindow} are passed
     * to.
     *
     * @param webViewClient the forwarding {@link WebViewClient}
     */
    public void setWebViewClient(WebViewClient webViewClient) {
      this.webViewClient = webViewClient;
    }

    @Override
    public void release() {
      if (flutterApi != null) {
        flutterApi.dispose(this, reply -> {});
      }
      flutterApi = null;
    }
  }

  /** Handles creating {@link WebChromeClient}s for a {@link WebChromeClientHostApiImpl}. */
  public static class WebChromeClientCreator {
    /**
     * Creates a {@link DownloadListenerHostApiImpl.DownloadListenerImpl}.
     *
     * @param flutterApi handles sending messages to Dart
     * @param webViewClient receives forwarded calls from {@link WebChromeClient#onCreateWindow}
     * @return the created {@link DownloadListenerHostApiImpl.DownloadListenerImpl}
     */
    public WebChromeClientImpl createWebChromeClient(
        WebChromeClientFlutterApiImpl flutterApi, WebViewClient webViewClient) {
      return new WebChromeClientImpl(flutterApi, webViewClient);
    }
  }

  /**
   * Creates a host API that handles creating {@link WebChromeClient}s.
   *
   * @param instanceManager maintains instances stored to communicate with Dart objects
   * @param webChromeClientCreator handles creating {@link WebChromeClient}s
   * @param flutterApi handles sending messages to Dart
   */
  public WebChromeClientHostApiImpl(
      InstanceManager instanceManager,
      WebChromeClientCreator webChromeClientCreator,
      WebChromeClientFlutterApiImpl flutterApi) {
    this.instanceManager = instanceManager;
    this.webChromeClientCreator = webChromeClientCreator;
    this.flutterApi = flutterApi;
  }

  @Override
  public void create(Long instanceId, Long webViewClientInstanceId) {
    final WebViewClient webViewClient =
        (WebViewClient) instanceManager.getInstance(webViewClientInstanceId);
    final WebChromeClient webChromeClient =
        webChromeClientCreator.createWebChromeClient(flutterApi, webViewClient);
    instanceManager.addInstance(webChromeClient, instanceId);
  }

  private static long getFileSize(Uri fileUri) {
    Cursor returnCursor = WebViewFlutterPlugin.activity.getApplicationContext().getContentResolver()
            .query(fileUri, null, null, null, null);
    returnCursor.moveToFirst();
    int sizeIndex = returnCursor.getColumnIndex(OpenableColumns.SIZE);
    return returnCursor.getLong(sizeIndex);
  }

  @TargetApi(7)
  static class ResultHandler {
    public boolean handleResult(int requestCode, int resultCode, Intent intent) {
      boolean handled = false;
      if (Build.VERSION.SDK_INT >= 21) {
        if (requestCode == FILECHOOSER_RESULTCODE) {
          Uri[] results = null;
          if (resultCode == Activity.RESULT_OK) {
            if (fileUri != null && getFileSize(fileUri) > 0) {
              results = new Uri[]{fileUri};
            } else if (videoUri != null && getFileSize(videoUri) > 0) {
              results = new Uri[]{videoUri};
            } else if (intent != null) {
              results = getSelectedFiles(intent);
            }
          }
          if (mUploadMessageArray != null) {
            mUploadMessageArray.onReceiveValue(results);
            mUploadMessageArray = null;
          }
          handled = true;
        }
      } else {
        if (requestCode == FILECHOOSER_RESULTCODE) {
          Uri result = null;
          if (resultCode == RESULT_OK && intent != null) {
            result = intent.getData();
          }
          if (mUploadMessage != null) {
            mUploadMessage.onReceiveValue(result);
            mUploadMessage = null;
          }
          handled = true;
        }
      }
      return handled;
    }
  }

  private static Uri[] getSelectedFiles(Intent data) {
    // we have one files selected
    if (data.getData() != null) {
      String dataString = data.getDataString();
      if (dataString != null) {
        return new Uri[]{Uri.parse(dataString)};
      }
    }
    // we have multiple files selected
    if (data.getClipData() != null) {
      final int numSelectedFiles = data.getClipData().getItemCount();
      Uri[] result = new Uri[numSelectedFiles];
      for (int i = 0; i < numSelectedFiles; i++) {
        result[i] = data.getClipData().getItemAt(i).getUri();
      }
      return result;
    }
    return null;
  }

  private static Uri getOutputFilename(String intentType) {
    String prefix = "";
    String suffix = "";

    if (intentType == MediaStore.ACTION_IMAGE_CAPTURE) {
      prefix = "image-";
      suffix = ".jpg";
    } else if (intentType == MediaStore.ACTION_VIDEO_CAPTURE) {
      prefix = "video-";
      suffix = ".mp4";
    }

    String packageName = WebViewFlutterPlugin.activity.getApplicationContext().getPackageName();
    File capturedFile = null;
    try {
      capturedFile = createCapturedFile(prefix, suffix);
    } catch (IOException e) {
      e.printStackTrace();
    }
    return FileProvider.getUriForFile(WebViewFlutterPlugin.activity.getApplicationContext(), packageName + ".fileprovider", capturedFile);
  }

  private static File createCapturedFile(String prefix, String suffix) throws IOException {
    String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
    String imageFileName = prefix + "_" + timeStamp;
    File storageDir = WebViewFlutterPlugin.activity.getApplicationContext().getExternalFilesDir(null);
    return File.createTempFile(imageFileName, suffix, storageDir);
  }

  private static Boolean acceptsImages(String[] types) {
    return isArrayEmpty(types) || arrayContainsString(types, "image");
  }

  private static Boolean acceptsVideo(String[] types) {
    return isArrayEmpty(types) || arrayContainsString(types, "video");
  }

  private static Boolean arrayContainsString(String[] array, String pattern) {
    for (String content : array) {
      if (content.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  private static Boolean isArrayEmpty(String[] arr) {
    // when our array returned from getAcceptTypes() has no values set from the
    // webview
    // i.e. <input type="file" />, without any "accept" attr
    // will be an array with one empty string element, afaik
    return arr.length == 0 || (arr.length == 1 && arr[0].length() == 0);
  }

  private static String[] getSafeAcceptedTypes(WebChromeClient.FileChooserParams params) {

    // the getAcceptTypes() is available only in api 21+
    // for lower level, we ignore it
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      return params.getAcceptTypes();
    }

    final String[] EMPTY = {};
    return EMPTY;
  }
}
