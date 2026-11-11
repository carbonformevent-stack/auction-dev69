# auction-dev69 — ระบบประมูลสินค้าสะสม

ระบบประมูลออนไลน์สำหรับสินค้าสะสม 4 ประเภท: **นาฬิกา, เครื่องประดับ, หนังสือเก่า, ภาพวาด**

- ผู้ใช้ 1 บัญชีเป็นได้ทั้ง **ผู้ขาย** และ **ผู้ประมูล**
- **Admin** ตรวจสอบและอนุมัติสินค้า แล้วนำไปจัดประมูล
- วิธีประมูลแรก: **FPSBA** (First-Price Sealed-Bid Auction) — อนาคตรองรับ English, Vickrey, Dutch
- เป้าหมาย: ขึ้น MVP ให้เร็วที่สุดเพื่อเก็บ feedback (Agile/Scrum, Sprint ละ 1 วัน)

## Tech stack

| ส่วน | เทคโนโลยี |
|---|---|
| Language / Framework | Ruby 4.0.9, Rails 8.1 |
| Database | SQLite 3 (ไฟล์ใน `storage/`, production ใช้ Railway Volume) |
| Authentication | Devise + `omniauth_openid_connect` → **Keycloak** (ไม่มี password ในระบบ) |
| Authorization | `User#role` enum: `user`, `admin` |
| Frontend | Hotwire (Turbo/Stimulus) + Tailwind CSS |
| Background jobs | Solid Queue (`SOLID_QUEUE_IN_PUMA=true` บน Railway) |
| File storage | Active Storage + S3-compatible storage |
| Test / Lint / Security | RSpec, FactoryBot, shoulda-matchers / RuboCop (omakase + rspec) / Brakeman, bundler-audit |
| CI | GitHub Actions (`.github/workflows/ci.yml`) |
| Deploy | [Railway](https://railway.com/) (app + Volume สำหรับ SQLite) |

## Setup เครื่อง (local development)

ต้องมี: [mise](https://mise.jdx.dev/) (หรือ rbenv/asdf), SQLite 3, libvips, Docker (Rancher Desktop / Docker Desktop — ใช้รัน Keycloak)

```bash
# 1. Ruby ตาม .ruby-version
mise install ruby@4.0.9 && mise use ruby@4.0.9

# 2. Keycloak สำหรับ dev (import realm "auction" ให้อัตโนมัติ ใช้เวลาเริ่มครั้งแรก ~20 วินาที)
docker compose up -d keycloak

# 3. ติดตั้ง gem, สร้าง .env จาก .env.example (ถ้ายังไม่มี), สร้าง database, start server
bin/setup
```

เปิด http://localhost:3000 แล้วกด "เข้าสู่ระบบด้วย Keycloak"

### Keycloak (dev)

ค่าใน `.env.example` ชี้ Keycloak ใน Docker อยู่แล้ว (`KEYCLOAK_ISSUER=http://localhost:8080/realms/auction`, client `auction-web`)
— ถ้ามี `.env` เก่าที่ค่า `KEYCLOAK_*` ว่าง ให้คัดลอก 3 บรรทัดนั้นจาก `.env.example` แล้วรีสตาร์ท `bin/dev`

| User ตัวอย่าง | รหัสผ่าน |
|---|---|
| `seller@example.com`, `seller2@example.com` | `password` |
| `admin@example.com` | `password` (ต้องตั้งเป็น admin ด้านล่าง) |

- Admin console: http://localhost:8080 (`admin` / `admin`) — เพิ่ม user ได้ที่ realm **auction** → Users หรือกด Register ที่หน้า login
- Realm / client / user ตัวอย่างอยู่ใน [config/keycloak/auction-realm.json](config/keycloak/auction-realm.json) (import เฉพาะตอน realm ยังไม่มี — แก้ไฟล์แล้วอยากโหลดใหม่: `docker compose down && docker compose up -d keycloak`)
- secret `auction-dev-secret` เป็นค่าสำหรับเครื่อง local เท่านั้น **ห้ามใช้กับ production**
- login ไม่ผ่าน: ดู `log/development.log` บรรทัด `[auth]` จะบอกสาเหตุ (เช่น ยังไม่ได้ตั้ง `KEYCLOAK_*` หรือ Keycloak ยังไม่ขึ้น)

### ลองใช้โดยไม่มี Keycloak (ล็อกอินจำลอง)

```bash
echo "DEV_LOGIN=1" >> .env
bin/rails db:seed        # สร้างบัญชีทดสอบ + สินค้าตัวอย่างครบทุกสถานะ (รันซ้ำได้)
bin/dev
```

เปิด http://localhost:3000/sign_in จะมีปุ่ม **เข้าเป็นผู้ขายทดสอบ** (`seller@example.test`) และ **เข้าเป็นแอดมินทดสอบ** (`admin@example.test`)
ปุ่มนี้ทำงานเฉพาะ `development` และต้องตั้ง `DEV_LOGIN=1` เองเท่านั้น (ดู `config/initializers/dev_login.rb`) — ใน production ปุ่มไม่แสดงและไม่มีทางใช้

### ตั้ง Admin คนแรก

```bash
# login ผ่าน Keycloak 1 ครั้งก่อน เพื่อให้ระบบสร้าง User
bin/rails db:seed    # ใช้ ADMIN_EMAIL จาก .env (ค่าตั้งต้น admin@example.com)
```

## คำสั่งที่ใช้บ่อย

```bash
bundle exec rspec                 # รัน test ทั้งหมด
bundle exec rspec spec/models     # รันเฉพาะโฟลเดอร์
bin/rubocop                       # lint (bin/rubocop -A เพื่อแก้อัตโนมัติ)
bin/brakeman --no-pager           # security scan
bin/bundler-audit                 # ตรวจ gem ที่มีช่องโหว่
bin/ci                            # รันทุกอย่างเหมือน CI
bin/dev                           # start server + Tailwind watcher (Procfile.dev)
```

## Environment variables

ค่า secret ทั้งหมดอ่านจาก ENV หรือ Rails credentials เท่านั้น ดูรายการเต็มใน [.env.example](.env.example)

| ตัวแปร | ใช้ที่ |
|---|---|
| `KEYCLOAK_ISSUER`, `KEYCLOAK_CLIENT_ID`, `KEYCLOAK_CLIENT_SECRET` | authentication |
| `APP_URL` (dev) / `APP_HOST`, `RAILWAY_PUBLIC_DOMAIN` (production) | redirect URI, host authorization, mailer |
| `RAILS_MASTER_KEY` | production |
| `ACTIVE_STORAGE_SERVICE`, `S3_*` | file storage (production default: `amazon`) |
| `ADMIN_EMAIL` | `db:seed` |

## Deploy บน Railway

Keycloak client ของ production ต้องเพิ่ม redirect URI `https://<domain>/users/auth/keycloak/callback`

Railway build จาก `Dockerfile` ตามค่าใน `railway.json` (health check ที่ `/up`)
ทุกครั้งที่ start server จะรัน `bin/rails db:prepare` อัตโนมัติ ซึ่งสร้าง/migrate ทั้ง primary, cache, queue, cable (ไฟล์ SQLite 4 ไฟล์ใน `/rails/storage`)

### ตั้งค่าครั้งแรก (ใน Railway dashboard)
1. **New Project → Deploy from GitHub repo** → `carbonformevent-stack/auction-dev69` branch `main`
2. ใน project เดียวกัน: **+ New → Bucket** แล้วที่ web service **คลิกขวา → Attach Volume** mount path `/rails/storage`
   (ถ้าไม่มี Volume ข้อมูล SQLite จะหายทุกครั้งที่ deploy และ scale ได้แค่ 1 replica)
3. ตั้ง Variables ของ web service ตามตารางด้านล่าง
4. **Settings → Networking → Generate Domain**
5. **Settings → Deploy → เปิด "Wait for CI"** เพื่อ deploy เฉพาะ commit ที่ CI ผ่าน

### Environment variables
| ตัวแปร | ค่า | หมายเหตุ |
|---|---|---|
| `RAILS_MASTER_KEY` | เนื้อหาไฟล์ `config/master.key` | **ห้าม commit** |
| `SOLID_QUEUE_IN_PUMA` | `true` | รัน background job ใน process เดียวกับ web |
| `RAILWAY_RUN_UID` | `0` | Volume ถูก mount เป็น root — ต้องตั้งเพื่อให้ container เขียนไฟล์ SQLite ได้ |
| `S3_BUCKET` | `${{Bucket.BUCKET}}` | Active Storage |
| `S3_ACCESS_KEY_ID` | `${{Bucket.ACCESS_KEY_ID}}` | |
| `S3_SECRET_ACCESS_KEY` | `${{Bucket.SECRET_ACCESS_KEY}}` | |
| `S3_REGION` | `${{Bucket.REGION}}` | |
| `S3_ENDPOINT` | `${{Bucket.ENDPOINT}}` | |
| `APP_HOST` | custom domain (ถ้ามี) เช่น `auction.example.com` | `RAILWAY_PUBLIC_DOMAIN` ถูกอนุญาตอัตโนมัติ |
| `KEYCLOAK_ISSUER` | `https://<keycloak>/realms/<realm>` | |
| `KEYCLOAK_CLIENT_ID` / `KEYCLOAK_CLIENT_SECRET` | จาก Keycloak client | **ห้าม commit** |
| `MAILER_SENDER` | อีเมลผู้ส่ง | |

> ชื่อ service (`Bucket`) ใน `${{...}}` ต้องตรงกับชื่อใน Railway project
> ถ้าใช้ Cloudflare R2 / AWS S3 แทน ให้ใส่ค่า `S3_*` ตรง ๆ

## เอกสาร

- [CONTRIBUTING.md](CONTRIBUTING.md) — branch, commit, Pull Request, code review
- [docs/ROADMAP.md](docs/ROADMAP.md) — milestones M0–M8
- [docs/coding-standard.md](docs/coding-standard.md)
- [docs/definition-of-ready.md](docs/definition-of-ready.md) / [docs/definition-of-done.md](docs/definition-of-done.md)
- [docs/architecture/auction-design.md](docs/architecture/auction-design.md) — การออกแบบการประมูล
- UI/UX: [Design canvas](https://claude.ai/artifact/QQMiqYfRigdsJ1rj4E4jLn#page-dcb81aee8d83) — **แหล่งอ้างอิงเดียว** ของการออกแบบ UI (แนวทาง B · Modern marketplace) ดูข้อกำหนดใน [coding-standard.md](docs/coding-standard.md#ui-design-ข้อกำหนดกลาง)
