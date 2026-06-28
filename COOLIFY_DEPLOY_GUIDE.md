# คู่มือ Deploy โปรเจกต์ใหม่ขึ้น Coolify (Hetzner)

> รวมบทเรียนจริงจากโปรเจกต์ SNT — เช็คลิสต์กันพลาดก่อนเสียเวลา

---

## 0️⃣ ตัดสินใจสถาปัตยกรรมก่อน (สำคัญสุด)

| คำถาม | ทางที่เวิร์ค (จาก SNT) |
|---|---|
| Frontend + Backend แยกกันไหม? | ถ้าแยก → **domain เดียว** ดีสุด: frontend (nginx) เสิร์ฟเว็บ + proxy `/api` ไป backend → ไม่มี CORS, ไม่เปลือง DuckDNS, cache ไม่งอแง |
| DB อยู่ไหน? | **Coolify Postgres บนเครื่องเดียวกัน** → latency ~0.5ms (อย่าใช้ DB คนละทวีปเด็ดขาด — บทเรียน Neon US-East) |
| Build pack? | **Dockerfile** (คุมเองชัดเจน) > Nixpacks (เดาเอง) |

---

## 1️⃣ เตรียม Dockerfile (กับดักที่เจอ)

**Backend (Node):**
- ใช้ `node:20-slim`
- ลง `openssl` ถ้าใช้ Prisma
- `prisma generate` ตอน build
- ใส่ `EXPOSE <port>`
- มี `/health` endpoint
- ⚠️ ใช้ `npm install` **ไม่ใช่** `npm ci` — ถ้า `package-lock` ไม่ sync, `npm ci` จะ fail `EUSAGE` (เจอกับ SNT)

**Frontend (CRA / Vite):**
- build → เสิร์ฟด้วย nginx
- ตั้ง `try_files ... /index.html` (SPA routing)
- `Cache-Control: no-store` ที่ `index.html` (กัน bundle เก่าค้าง)
- ⚠️ CRA ฝัง env ตอน build → ต้องส่งเป็น **build ARG** (Coolify: ติ๊ก "Available at Buildtime")

---

## 2️⃣ ตั้งค่าใน Coolify — 4 ช่องที่พังบ่อยที่สุด

| ช่อง | ต้องตั้ง | ถ้าพลาด |
|---|---|---|
| Base Directory | `/backend` (โฟลเดอร์ที่มี Dockerfile) | Dockerfile not found |
| Dockerfile Location | `/Dockerfile` (relative กับ Base Dir) | หาไฟล์ไม่เจอ |
| Ports Exposes | = พอร์ตจริงที่แอป listen (เช่น `5001`) | 502 Bad Gateway |
| Port Mappings | **ลบให้ว่าง** (default `3000:3000`) | ชนพอร์ต |
| Pre-deployment | **ลบ** `php artisan migrate` (default Laravel) | deploy fail |

---

## 3️⃣ Database

- `+ Add Resource` → **PostgreSQL 17** → Coolify ให้ user/pass/internal URL
- ใส่ใน backend env: `DATABASE_URL` (**+ `DIRECT_URL` ถ้าใช้ Prisma — ลืมบ่อย!**) = internal URL
- ย้ายข้อมูล: `pg_dump -Fc` → `pg_restore` (เปิด public port ชั่วคราว แล้วปิด)
- ⚠️ ระวัง FK delete rule ตอนลบข้อมูล (`RESTRICT` / `SET NULL` / `CASCADE`) — **ลบลูกก่อนพ่อ**

---

## 4️⃣ Domain + DNS + SSL

- ⚠️ DuckDNS auto กรอก **IP บ้านคุณ ไม่ใช่ IP server!** → ต้องแก้เป็น `178.105.160.213` เอง (ไม่งั้น timeout)
- DuckDNS ฟรี 5 domain — เต็มแล้วใช้ subdomain เดียว + nginx proxy
- ใส่ domain ใน Coolify → Traefik ขอ Let's Encrypt อัตโนมัติ (HTTP→HTTPS redirect ให้เอง)

---

## 5️⃣ กับดักเพิ่มเติม (เช็คก่อนเสียเวลา)

- **CORS** (ถ้าแยก domain): backend ต้อง allow origin ของ frontend (`FRONTEND_URL` env) + `maxAge` cache preflight
- **Browser cache:** หลัง deploy ใหม่ ถ้า login ไม่ได้ → hard refresh / `no-store` index.html
- **Upload ไฟล์ไทย:** ไฟล์จากทะเบียนมักเป็น TIS-620 ไม่ใช่ UTF-8 → ต้องแปลง (`iconv`) ไม่งั้นไทยเพี้ยน
- **RAM 4GB จำกัด:** CRA build กินแรม ระวัง build ล้มถ้ารันหลายอันพร้อมกัน

---

## 6️⃣ Verify (curl ก่อนเชื่อ UI)

```bash
curl -I https://your.domain/           # 200/302
curl https://your.domain/api/health    # {"status":"ok"}
```
