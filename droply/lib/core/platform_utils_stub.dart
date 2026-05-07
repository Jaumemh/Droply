// Stub para plataformas no-web (Android, iOS, Desktop).
// sessionStorage siempre devuelve null; location.assign no hace nada.

String? sessionStorageGet(String key) => null;

void sessionStorageSet(String key, String value) {}

void sessionStorageRemove(String key) {}

void locationAssign(String url) {}
