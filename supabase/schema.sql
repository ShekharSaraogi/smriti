-- Run this once in your Supabase project's SQL Editor (left sidebar ->
-- SQL Editor -> New query -> paste this in -> Run). It creates the 3
-- tables the phone app syncs into, mirroring the local SQLite schema in
-- lib/db/database_helper.dart.

-- patients.id is a uuid rather than reusing the phone's own local integer
-- id, because every patient's phone locally calls its own single patient
-- "id 1" — that's fine on-device, but they can't all be "1" in one shared
-- cloud table. device_uuid (generated once per phone install, see
-- lib/sync/device_identity.dart) is what actually tells them apart here.
create table patients (
  id uuid primary key default gen_random_uuid(),
  device_uuid text unique not null,
  name text not null,
  preferred_language text not null default 'en',
  daily_routine text,
  created_at timestamptz not null
);

create table game_sessions (
  id bigserial primary key,
  patient_id uuid not null references patients (id),
  game_type text not null,
  difficulty_tier integer not null,
  accuracy double precision not null,
  response_time_seconds double precision not null,
  correct_answers integer not null,
  total_answers integer not null,
  timestamp timestamptz not null
);

create table reminders (
  id bigserial primary key,
  patient_id uuid not null references patients (id),
  -- The phone's own local row id for this reminder. A reminder syncs more
  -- than once over its life (once "pending", again once marked done) —
  -- local_id + patient_id together is what the app upserts on so a later
  -- sync updates this same row instead of creating a duplicate.
  local_id integer not null,
  type text not null,
  scheduled_time timestamptz not null,
  status text not null,
  completed_at timestamptz,
  unique (patient_id, local_id)
);

-- Row Level Security is on, but with a wide-open policy for now — there's
-- no patient/caregiver login system yet, so there's no real identity to
-- restrict access by. This is fine for a hackathon build with placeholder
-- data, but MUST be replaced with real per-patient policies (tied to
-- caregiver accounts) before this ever holds real patient data.
alter table patients enable row level security;
alter table game_sessions enable row level security;
alter table reminders enable row level security;

create policy "Open for hackathon build - tighten before real use"
  on patients for all using (true) with check (true);
create policy "Open for hackathon build - tighten before real use"
  on game_sessions for all using (true) with check (true);
create policy "Open for hackathon build - tighten before real use"
  on reminders for all using (true) with check (true);
