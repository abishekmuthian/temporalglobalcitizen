import 'dart:convert';
import 'package:http/http.dart' as http;

class DataFetcher {
  static Future<Map<String, int>> getGlobalCitizenData(String username) async {
    final String url =
        'https://temporal-global-citizen-server.fly.dev/score/?username=$username';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        int points = jsonResponse['points'] as int? ?? 0;
        // Now handling 'actions' as an int
        int actions = jsonResponse['actions'] as int? ?? 0;
        return {'points': points, 'actions': actions};
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Error sending request: $e');
    }
    return {
      'points': 0,
      'actions': 0
    }; // Return default values if the request fails
  }

  static Future<Map<String, String>> getWalletData(
      String username, int level, int points, String time) async {
    final String url =
        'https://temporal-global-citizen-server.fly.dev/wallet/?username=$username&level=$level&points=$points&time=$time';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        String url = jsonResponse['url'] as String? ?? '';
        return {'url': url};
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Error sending request: $e');
    }
    return {
      'url': '',
    };
  }
}
