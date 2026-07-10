# เที่ยวด้วยกัน — Travel Buddy

Webapp จัดการทริปสำหรับกลุ่มเพื่อน รองรับ LocalStorage และ Supabase

## วิธีใช้ (LocalStorage — ไม่ต้องตั้งค่าอะไร)

เปิด `index.html` ใน Chrome/Edge/Firefox ได้เลย ข้อมูลเก็บในเครื่อง

## วิธีตั้งค่า Supabase (แชร์ข้ามเครื่อง / เปิดผ่านมือถือ)

### 1. สมัคร Supabase

ไปที่ [supabase.com](https://supabase.com) → Sign up → Create project (ฟรี)

### 2. เอา Project URL + anon key

ใน Dashboard → **Settings → API**:
- `Project URL` — เช่น `https://xxxxx.supabase.co`
- `anon public` — คีย์ยาว ๆ

### 3. ใส่ค่าใน `index.html`

เปิด `index.html` หาบรรทัดนี้:

```js
const SUPABASE_URL = '';      // ← ใส่ URL
const SUPABASE_ANON_KEY = ''; // ← ใส่ anon key
```

### 4. ตั้งค่าตารางใน Supabase

Dashboard → **SQL Editor** → New Query → วางเนื้อหา `supabase-schema.sql` → Run

หรือเปิด `supabase-schema.sql` แล้วกด Run

### 5. เปิด Authentication (Email)

Dashboard → **Authentication → Providers → Email**
- เปิด **Enable Signups** (`ON`)
- ตั้ง **Confirm email** ตามต้องการ (`OFF` ถ้าอยากให้สมัครแล้วเข้าใช้ได้เลย)

### 6. เปิด Auth > Settings

- **Site URL**: ใส่ URL ที่ใช้เปิดเว็บ (หรือ `http://localhost:8080`)
- ถ้าจะเปิดบนมือถือ ให้ใส่ URL จริง หรือ IP ใน network

### 7. ทดสอบ

เปิด `index.html` → ควรเจอหน้า Login → สมัคร/เข้าสู่ระบบ → ข้อมูล sync อัตโนมัติ

## เปิดบนมือถือ (ไม่มี Supabase)

```bash
cd travel-buddy
python -m http.server 8080
```

หา IP เครื่อง (`ipconfig`) → เปิด `http://<IP>:8080` บนมือถือ (WiFi เดียวกัน)

## เปิดบนมือถือ (กับ Supabase)

- Deploy ไปที่ GitHub Pages / Vercel / Netlify
- หรือใช้ `python -m http.server` แล้วใช้ ngrok

### Deploy ฟรีด้วย Vercel

```bash
npm i -g vercel
vercel --cwd path/to/travel-buddy
```

ได้ URL สาธารณะทันที → เอาไปตั้งใน Supabase **Authentication > Site URL** ด้วย

## ข้อมูล

- ฟอนต์ Sarabun ภาษาไทย
- แผนที่ Leaflet + OpenStreetMap (ไม่ต้องใช้ API Key)
- Material Icons Outlined
