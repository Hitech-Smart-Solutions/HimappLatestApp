import 'package:dio/dio.dart';
import '../shared_prefs_helper.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://d3dbm3mdf4kbfk.cloudfront.net', // Production
      // baseUrl: 'https://d94acvrm8bvo5.cloudfront.net', // test
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SharedPrefsHelper.getToken();

          // print('➡️ API REQUEST: ${options.method} ${options.uri}');
          // print('➡️ Headers BEFORE: ${options.headers}');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // print('➡️ Headers AFTER: ${options.headers}');
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // 🔥 future: logout / token refresh
            print('Unauthorized - token expired');
          }
          return handler.next(error);
        },
      ),
    );
}
