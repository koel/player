import 'package:http/http.dart';

class HttpResponseException implements Exception {
  final Response response;

  HttpResponseException({required this.response});

  @override
  String toString() {
    return 'Request failed with status code ${response.statusCode}.';
  }

  factory HttpResponseException.fromResponse(Response response) {
    return HttpResponseException(response: response);
  }
}
