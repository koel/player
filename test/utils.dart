import 'dart:convert';
import 'dart:io';

dynamic jsonFromFile(String filePath) {
  return jsonDecode(File(filePath).readAsStringSync());
}
