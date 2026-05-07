/// Helper multiplataforma para APIs de navegador (sessionStorage, location).
/// En web usa dart:html; en otras plataformas usa stubs sin operación.
export 'platform_utils_stub.dart'
    if (dart.library.html) 'platform_utils_web.dart';
