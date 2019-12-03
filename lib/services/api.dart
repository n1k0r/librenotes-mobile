import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class APIResult {
  final bool success;
  final Map<String, dynamic> data;
  final String error;

  const APIResult({this.success, this.data, this.error});
}

Future<APIResult> request(String url, {Map<String, dynamic> data, String token}) async {
  var encUrl = Uri.encodeFull(url);
  http.Response response;
  try {
    response = await http.post(
      encUrl,
      headers: {
        HttpHeaders.contentTypeHeader: ContentType.json.value,
        if (token != null)
          HttpHeaders.authorizationHeader: 'Token $token',
      },
      body: json.encode(data),
    );
  } on SocketException {
    return APIResult(success: false, error: 'Connection error');
  }

  var result;
  try {
    result = json.decode(utf8.decode(response.bodyBytes));
  } on FormatException {
    return APIResult(success: false, error: 'Server error');
  }

  if (response.statusCode != 200) {
    return APIResult(success: false, error: result['error']);
  }

  return APIResult(success: true, data: result);
}

Future<String> auth(String server, String username, String password) async {
  var req = await request(
    'http://$server/api/token/',
    data: {
      'username': username,
      'password': password,
    },
  );

  if (!req.success) {
    return null;
  }

  var token = req.data['token'];
  return token;
}

Future<Map<String, dynamic>> sync(String server, String token, Map<String, dynamic> data) async {
  var req = await request(
    'http://$server/api/sync/',
    token: token,
    data: data,
  );

  if (!req.success) {
    return null;
  }

  var result = req.data;
  return result;
}
