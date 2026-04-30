import 'dart:html' as html;

void applyNoIndexMeta() {
  void setMeta(String name, String content) {
    final existing = html.document.head?.querySelector('meta[name="$name"]');
    if (existing != null) {
      existing.setAttribute('content', content);
      return;
    }

    final meta = html.MetaElement()
      ..name = name
      ..content = content;
    html.document.head?.children.add(meta);
  }

  setMeta('robots', 'noindex, nofollow, noarchive');
  setMeta('googlebot', 'noindex, nofollow, noarchive');
}

