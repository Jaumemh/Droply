// Implementación web usando dart:html.
import 'dart:html' as html;

String? sessionStorageGet(String key) =>
    html.window.sessionStorage[key];

void sessionStorageSet(String key, String value) =>
    html.window.sessionStorage[key] = value;

void sessionStorageRemove(String key) =>
    html.window.sessionStorage.remove(key);

void locationAssign(String url) =>
    html.window.location.assign(url);
