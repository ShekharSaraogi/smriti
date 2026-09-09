// Fill these in with your own Supabase project's values, from the
// Supabase dashboard: Project Settings -> Data API.
//   url     -> "Project URL"
//   anonKey -> "anon public" key (NOT the service_role key — that one
//              must never be shipped inside an app)
//
// Until both are filled in, isConfigured stays false, so Supabase never
// gets initialized and sync never runs — the app behaves exactly as it
// always has. Nothing else in the app depends on this.
class SupabaseConfig {
  static const String url = 'https://bkakitegsockbwkxvaja.supabase.co';
  static const String anonKey = 'sb_publishable_2fM4xxKWKp5wtDPDY8lukQ_B9FBlZVU';

  static bool get isConfigured =>
      url != 'YOUR_SUPABASE_URL' && anonKey != 'YOUR_SUPABASE_ANON_KEY';
}
