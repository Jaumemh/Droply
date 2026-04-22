import 'package:http/http.dart' as http;

import 'app_http_client_io.dart'
    if (dart.library.html) 'app_http_client_web.dart';

http.Client createAppHttpClient() => createHttpClient();
