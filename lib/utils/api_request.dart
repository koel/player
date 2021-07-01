import 'dart:convert';

import 'package:app/utils/preferences.dart';
import 'package:http/http.dart' as Http;

enum HttpMethod { get, post, patch, put, delete }

Future<Map<String, dynamic>> request(
  HttpMethod method,
  String path, {
  Object data = const {},
}) async {
  late Http.Response response;

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
      response = await Http.get(uri, headers: headers);
      break;
    case HttpMethod.post:
      response = await Http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      break;
    case HttpMethod.patch:
      response = await Http.patch(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      break;
    case HttpMethod.put:
      response = await Http.put(
        uri,
        headers: headers,
        body: json.encode(data),
      );
      break;
    case HttpMethod.delete:
      response =
          await Http.delete(uri, headers: headers, body: json.encode(data));
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

Future<Map<String, dynamic>> get(String path) async =>
    request(HttpMethod.get, path);

Future<Map<String, dynamic>> post(
  String path, {
  Object data = const {},
}) async =>
    request(HttpMethod.post, path, data: data);

Future<Map<String, dynamic>> patch(
  String path, {
  Object data = const {},
}) async =>
    request(HttpMethod.patch, path, data: data);

Future<Map<String, dynamic>> put(
  String path, {
  Object data = const {},
}) async =>
    request(HttpMethod.put, path, data: data);

Future<Map<String, dynamic>> delete(
  String path, {
  Object data = const {},
}) async =>
    request(HttpMethod.delete, path, data: data);
