import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiRequestHelper {
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(url);

    try {
      if (response.statusCode == 200) {
        String jsonData = response.body;
        var decodedData = jsonDecode(jsonData);
        return decodedData;
      } else {
        return "failed";
      }
    } catch (error) {
      return "failed";
    }
  }
}
