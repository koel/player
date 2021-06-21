import 'dart:convert';

import 'package:app/utils/preferences.dart';
import 'package:http/http.dart' as BaseHttp;

enum HttpMethod { get, post, patch, put, delete }

class ApiRequest {
  static Future<Map<String, dynamic>> request(HttpMethod method, String path,
      {Object data = const {}}) async {
    late BaseHttp.Response response;

    Uri uri = Uri.parse("${await apiBaseUrl}/$path");

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    String? token = await apiToken;

    if (token != null) {
      headers['Authorization'] = "Bearer $token";
    }

    switch (method) {
      case HttpMethod.get:
        response = await BaseHttp.get(uri, headers: headers);
        break;
      case HttpMethod.post:
        response = await BaseHttp.post(
          uri,
          headers: headers,
          body: json.encode(data),
        );
        break;
      case HttpMethod.patch:
        response = await BaseHttp.patch(
          uri,
          headers: headers,
          body: json.encode(data),
        );
        break;
      case HttpMethod.put:
        response = await BaseHttp.put(
          uri,
          headers: headers,
          body: json.encode(data),
        );
        break;
      case HttpMethod.delete:
        response = await BaseHttp.delete(uri,
            headers: headers, body: json.encode(data));
        break;
      default:
        throw ArgumentError.value(method);
    }

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(response);
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    return ApiRequest.request(HttpMethod.get, path);
  }

  static Future<Map<String, dynamic>> post(String path,
      {Object data = const {}}) async {
    return ApiRequest.request(HttpMethod.post, path, data: data);
  }

  static Future<Map<String, dynamic>> patch(String path,
      {Object data = const {}}) async {
    return ApiRequest.request(HttpMethod.patch, path, data: data);
  }

  static Future<Map<String, dynamic>> put(String path,
      {Object data = const {}}) async {
    return ApiRequest.request(HttpMethod.put, path, data: data);
  }

  static Future<Map<String, dynamic>> delete(String path,
      {Object data = const {}}) async {
    return ApiRequest.request(HttpMethod.delete, path, data: data);
  }
}
