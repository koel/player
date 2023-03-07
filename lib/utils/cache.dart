import 'package:get_storage/get_storage.dart';

final GetStorage storage = GetStorage('Cache');

dynamic remember(String key, Function([dynamic restArgs]) resolver) {
  Function.apply(resolver, []);
}
