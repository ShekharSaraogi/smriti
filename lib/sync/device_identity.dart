import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// A random id generated once per app install, then remembered forever
// after that. The local database only ever has one patient row (always
// id 1 — see DatabaseHelper.getOrCreateDefaultPatient), which is fine for
// purely local use, but many different patients' phones all sync into the
// same shared Supabase project, and they can't all claim to be "patient
// 1" there. This id is what actually tells them apart in the cloud.
class DeviceIdentity {
  DeviceIdentity._privateConstructor();
  static final DeviceIdentity instance = DeviceIdentity._privateConstructor();

  static const _prefsKey = 'device_uuid';
  String? _cached;

  Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null) {
      _cached = existing;
      return existing;
    }

    final generated = const Uuid().v4();
    await prefs.setString(_prefsKey, generated);
    _cached = generated;
    return generated;
  }
}
