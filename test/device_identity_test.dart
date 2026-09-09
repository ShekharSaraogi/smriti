import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smriti/sync/device_identity.dart';

void main() {
  test('generates a uuid, then returns that same one on later calls', () async {
    SharedPreferences.setMockInitialValues({});

    final first = await DeviceIdentity.instance.getOrCreate();
    expect(first, isNotEmpty);

    final second = await DeviceIdentity.instance.getOrCreate();
    expect(second, first);
  });
}
