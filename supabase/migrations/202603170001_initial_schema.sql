create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  locale text not null default 'tr',
  timezone text not null default 'Europe/Istanbul',
  consent_analytics boolean not null default false,
  consent_personalization boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  platform text not null,
  fcm_token text not null,
  app_version text,
  locale text,
  timezone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_user_devices_user_id on public.user_devices(user_id);

create table if not exists public.prayer_calculation_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  method text not null,
  madhab text not null,
  high_latitude_rule text not null default 'middle_of_the_night',
  fajr_offset_minutes int not null default 0,
  dhuhr_offset_minutes int not null default 0,
  asr_offset_minutes int not null default 0,
  maghrib_offset_minutes int not null default 0,
  isha_offset_minutes int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  label text not null,
  latitude numeric(10,7) not null,
  longitude numeric(10,7) not null,
  country_code text,
  city text,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_locations_user_id on public.locations(user_id);

create table if not exists public.daily_prayer_times (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  prayer_date date not null,
  fajr timestamptz not null,
  sunrise timestamptz not null,
  dhuhr timestamptz not null,
  asr timestamptz not null,
  maghrib timestamptz not null,
  isha timestamptz not null,
  calculation_method text not null,
  timezone text not null,
  created_at timestamptz not null default now(),
  unique(user_id, prayer_date)
);
create index if not exists idx_daily_prayer_times_user_date on public.daily_prayer_times(user_id, prayer_date);

create table if not exists public.quran_surahs (
  id smallint primary key,
  name_arabic text not null,
  name_latin text not null,
  revelation_type text not null,
  ayah_count smallint not null
);

create table if not exists public.quran_ayahs (
  id bigint primary key,
  surah_id smallint not null references public.quran_surahs(id) on delete cascade,
  ayah_number smallint not null,
  page_number smallint not null,
  juz_number smallint not null,
  hizb_number smallint not null,
  arabic_uthmani text not null,
  arabic_simple text not null,
  root_tokens text[],
  unique(surah_id, ayah_number)
);
create index if not exists idx_quran_ayahs_surah_ayah on public.quran_ayahs(surah_id, ayah_number);
create index if not exists idx_quran_ayahs_roots on public.quran_ayahs using gin(root_tokens);

create table if not exists public.quran_translations (
  id uuid primary key default gen_random_uuid(),
  ayah_id bigint not null references public.quran_ayahs(id) on delete cascade,
  language_code text not null,
  translator text not null,
  text_content text not null,
  unique(ayah_id, language_code, translator)
);
create index if not exists idx_quran_translations_lang_ayah on public.quran_translations(language_code, ayah_id);

create table if not exists public.quran_audio_reciters (
  id uuid primary key default gen_random_uuid(),
  reciter_code text not null unique,
  display_name text not null,
  bitrate int not null default 128
);

create table if not exists public.quran_audio_tracks (
  id uuid primary key default gen_random_uuid(),
  ayah_id bigint not null references public.quran_ayahs(id) on delete cascade,
  reciter_id uuid not null references public.quran_audio_reciters(id) on delete cascade,
  audio_url text not null,
  duration_seconds int,
  unique(ayah_id, reciter_id)
);

create table if not exists public.quran_bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  surah_id smallint not null references public.quran_surahs(id) on delete cascade,
  ayah_number smallint not null,
  category text not null default 'general',
  note text,
  created_at timestamptz not null default now()
);
create index if not exists idx_quran_bookmarks_user on public.quran_bookmarks(user_id);

create table if not exists public.quran_last_reads (
  user_id uuid primary key references public.users(id) on delete cascade,
  surah_id smallint not null references public.quran_surahs(id) on delete cascade,
  ayah_number smallint not null,
  scroll_offset double precision not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.hadith_collections (
  id uuid primary key default gen_random_uuid(),
  key_name text not null unique,
  display_name text not null
);

create table if not exists public.hadith_entries (
  id uuid primary key default gen_random_uuid(),
  collection_id uuid not null references public.hadith_collections(id) on delete cascade,
  hadith_number text not null,
  book text,
  chapter text,
  arabic_text text not null,
  translation_text text not null,
  language_code text not null default 'en'
);

create table if not exists public.daily_content_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  content_date date not null,
  content_type text not null,
  source_table text not null,
  source_id uuid not null,
  notify_at timestamptz,
  delivered_at timestamptz,
  unique(user_id, content_date, content_type)
);

create table if not exists public.dua_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  sort_order int not null default 0
);

create table if not exists public.duas (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.dua_categories(id) on delete cascade,
  title text not null,
  arabic_text text not null,
  source_reference text
);

create table if not exists public.dua_translations (
  id uuid primary key default gen_random_uuid(),
  dua_id uuid not null references public.duas(id) on delete cascade,
  language_code text not null,
  transliteration text,
  translation text not null,
  unique(dua_id, language_code)
);

create table if not exists public.dua_audio (
  id uuid primary key default gen_random_uuid(),
  dua_id uuid not null references public.duas(id) on delete cascade,
  reciter_name text not null,
  audio_url text not null
);

create table if not exists public.user_favorite_duas (
  user_id uuid not null references public.users(id) on delete cascade,
  dua_id uuid not null references public.duas(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, dua_id)
);

create table if not exists public.dhikr_presets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  target_count int not null
);

create table if not exists public.dhikr_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  preset_id uuid references public.dhikr_presets(id) on delete set null,
  dhikr_text text not null,
  total_count int not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists idx_dhikr_sessions_user_started on public.dhikr_sessions(user_id, started_at desc);

create table if not exists public.dhikr_stats_daily (
  user_id uuid not null references public.users(id) on delete cascade,
  stat_date date not null,
  total_count int not null default 0,
  sessions_count int not null default 0,
  primary key(user_id, stat_date)
);

create table if not exists public.achievements (
  id uuid primary key default gen_random_uuid(),
  key_name text not null unique,
  title text not null,
  threshold int not null
);

create table if not exists public.user_achievements (
  user_id uuid not null references public.users(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  unlocked_at timestamptz not null default now(),
  primary key(user_id, achievement_id)
);

create table if not exists public.hijri_calendar_days (
  gregorian_date date primary key,
  hijri_year smallint not null,
  hijri_month smallint not null,
  hijri_day smallint not null
);

create table if not exists public.islamic_events (
  id uuid primary key default gen_random_uuid(),
  hijri_month smallint not null,
  hijri_day smallint not null,
  name text not null,
  reminder_default_hours int not null default 24
);

create table if not exists public.user_event_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_id uuid not null references public.islamic_events(id) on delete cascade,
  remind_before_hours int not null default 24,
  is_enabled boolean not null default true,
  unique(user_id, event_id)
);

create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  role text not null,
  content text not null,
  citations jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_ai_messages_conversation_created on public.ai_messages(conversation_id, created_at desc);

create table if not exists public.ai_feedback (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.ai_messages(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  rating smallint not null check (rating between 1 and 5),
  feedback_text text,
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  plan_code text not null,
  store text not null,
  status text not null,
  started_at timestamptz not null,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_subscriptions_user_status on public.subscriptions(user_id, status);

alter table public.users enable row level security;
alter table public.user_devices enable row level security;
alter table public.prayer_calculation_profiles enable row level security;
alter table public.locations enable row level security;
alter table public.daily_prayer_times enable row level security;
alter table public.quran_bookmarks enable row level security;
alter table public.quran_last_reads enable row level security;
alter table public.user_favorite_duas enable row level security;
alter table public.dhikr_sessions enable row level security;
alter table public.dhikr_stats_daily enable row level security;
alter table public.user_achievements enable row level security;
alter table public.user_event_reminders enable row level security;
alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_feedback enable row level security;
alter table public.subscriptions enable row level security;

create policy if not exists users_owner on public.users
  for all using (auth.uid() = id) with check (auth.uid() = id);
create policy if not exists user_devices_owner on public.user_devices
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists prayer_profiles_owner on public.prayer_calculation_profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists locations_owner on public.locations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists daily_prayer_times_owner on public.daily_prayer_times
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists quran_bookmarks_owner on public.quran_bookmarks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists quran_last_reads_owner on public.quran_last_reads
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists favorite_duas_owner on public.user_favorite_duas
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists dhikr_sessions_owner on public.dhikr_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists dhikr_stats_owner on public.dhikr_stats_daily
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists user_achievements_owner on public.user_achievements
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists user_event_reminders_owner on public.user_event_reminders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists ai_conversations_owner on public.ai_conversations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists ai_messages_owner on public.ai_messages
  for all using (
    exists (
      select 1 from public.ai_conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.ai_conversations c
      where c.id = conversation_id and c.user_id = auth.uid()
    )
  );
create policy if not exists ai_feedback_owner on public.ai_feedback
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy if not exists subscriptions_owner on public.subscriptions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
