import 'package:app/utils/api_request.dart';
import 'package:flutter/foundation.dart';

class DataProvider with ChangeNotifier {
  Future<void> fetchData() async {
    final Map<String, dynamic> data = await ApiRequest.get('data');
    print(data);
  }
}