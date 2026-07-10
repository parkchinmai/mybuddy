-- ═══════════════════════════════════════════════════════════
--  เที่ยวด้วยกัน — Supabase Schema
--  ไปที่ Supabase Dashboard → SQL Editor → วางแล้วกด Run
-- ═══════════════════════════════════════════════════════════

-- 1. Trips — เก็บข้อมูลทริป, members, expenses ฯลฯ ใน JSONB
CREATE TABLE IF NOT EXISTS trips (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT DEFAULT 'flight',
  pin TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  data JSONB DEFAULT '{}'::jsonb
);

ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id);

-- 2. Trip Collaborators — ผู้ที่ถูกเชิญให้ร่วมทริป
DROP TABLE IF EXISTS trip_collaborators CASCADE;
CREATE TABLE trip_collaborators (
  trip_id TEXT REFERENCES trips(id) ON DELETE CASCADE NOT NULL,
  email TEXT NOT NULL,
  owner_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (trip_id, email)
);

ALTER TABLE trip_collaborators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owner select"
  ON trip_collaborators FOR SELECT
  USING (owner_id = auth.uid());

CREATE POLICY "Owner insert"
  ON trip_collaborators FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Owner delete"
  ON trip_collaborators FOR DELETE
  USING (owner_id = auth.uid());

-- Collaborator อ่านรายการของตัวเอง (ใช้ตอน "Trip access" query trips)
CREATE POLICY "Collaborator select own"
  ON trip_collaborators FOR SELECT
  USING (email = auth.jwt() ->> 'email');

-- 3. Admins (เห็นทุกทริป — สำหรับ admin)
CREATE TABLE IF NOT EXISTS admins (
  email TEXT PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read admins" ON admins;
CREATE POLICY "Anyone can read admins"
  ON admins FOR SELECT
  USING (true);

INSERT INTO admins (email) VALUES ('ronnachai.wijit@gmail.com')
ON CONFLICT (email) DO NOTHING;

-- 4. Trip access - update policy to allow public access
DROP POLICY IF EXISTS "Trip access" ON trips;
DROP POLICY IF EXISTS "Public read trips" ON trips;
DROP POLICY IF EXISTS "Public insert trips" ON trips;
DROP POLICY IF EXISTS "Public update trips" ON trips;
DROP POLICY IF EXISTS "Public delete trips" ON trips;

CREATE POLICY "Public read trips" ON trips FOR SELECT USING (true);
CREATE POLICY "Public insert trips" ON trips FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update trips" ON trips FOR UPDATE USING (true);
CREATE POLICY "Public delete trips" ON trips FOR DELETE USING (true);

-- 5. RPC functions (bypass schema cache)
DROP FUNCTION IF EXISTS add_collaborator(TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS remove_collaborator(TEXT, TEXT);
DROP FUNCTION IF EXISTS list_collaborators(TEXT);
DROP FUNCTION IF EXISTS list_my_collabs();
CREATE OR REPLACE FUNCTION add_collaborator(p_trip_id TEXT, p_email TEXT, p_owner_id UUID)
RETURNS void SECURITY DEFINER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO trip_collaborators (trip_id, email, owner_id) VALUES (p_trip_id, p_email, p_owner_id)
  ON CONFLICT (trip_id, email) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION remove_collaborator(p_trip_id TEXT, p_email TEXT)
RETURNS void SECURITY DEFINER LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM trip_collaborators WHERE trip_id = p_trip_id AND email = p_email;
END;
$$;

CREATE OR REPLACE FUNCTION list_collaborators(p_trip_id TEXT)
RETURNS TABLE(email TEXT, created_at TIMESTAMPTZ)
SECURITY DEFINER LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT tc.email, tc.created_at FROM trip_collaborators tc WHERE tc.trip_id = p_trip_id;
END;
$$;

CREATE OR REPLACE FUNCTION list_my_collabs()
RETURNS TABLE(trip_id TEXT, email TEXT)
SECURITY DEFINER LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT tc.trip_id, tc.email FROM trip_collaborators tc
  WHERE tc.owner_id = auth.uid() OR tc.email = auth.jwt() ->> 'email';
END;
$$;

-- 6. Profiles — ข้อมูลผู้ใช้ (ชื่อ เบอร์โทร ธนาคาร เลขบัญชี รูปโปรไฟล์ สีพื้น)
CREATE TABLE IF NOT EXISTS profiles (
  phone TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  bank_name TEXT DEFAULT '',
  bank_account TEXT DEFAULT '',
  avatar TEXT DEFAULT '🐱',
  color TEXT DEFAULT '#F8C8DC',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Public insert profiles" ON profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update profiles" ON profiles FOR UPDATE USING (true);

-- 7. Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trips_updated_at ON trips;
CREATE TRIGGER trips_updated_at
  BEFORE UPDATE ON trips
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
