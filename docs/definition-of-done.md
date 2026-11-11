# Definition of Done (DoD)

งานจะถือว่า "เสร็จ" และปิด issue ได้เมื่อผ่านทุกข้อ:

## บังคับ

- [ ] **ผ่าน CI** ทั้งหมด: lint (RuboCop), security (Brakeman, bundler-audit), test (RSpec)
- [ ] **มี test** สำหรับพฤติกรรมใหม่/ที่แก้ — รวม boundary case ใน Acceptance Criteria
- [ ] **Code review ผ่าน** — ได้ approval อย่างน้อย 1 คน และไม่มี `blocker:` ค้าง
- [ ] **ทำตาม Acceptance Criteria** ครบทุกข้อ (ผู้ review ไล่เช็คกับ issue)
- [ ] **อัปเดตเอกสาร** ที่เกี่ยวข้อง: README, docs/, `.env.example` (ถ้ามี ENV ใหม่), architecture doc (ถ้าเปลี่ยน design)

## ตรวจด้วย

- [ ] ไม่มี secret / ข้อมูลส่วนตัวใน code, log หรือ commit
- [ ] Migration รันได้ทั้ง up และ down
- [ ] ตรวจสิทธิ์ครบ (guest / user / เจ้าของ / admin)
- [ ] หน้าจอใช้งานได้ที่ความกว้างมือถือ (ถ้ามี UI)
- [ ] UI ตรงกับ [Design canvas](https://claude.ai/artifact/QQMiqYfRigdsJ1rj4E4jLn#page-dcb81aee8d83) — ส่วนที่ต่างมีเหตุผลใน PR (ดู [coding-standard.md](coding-standard.md#ui-design-ข้อกำหนดกลาง))
- [ ] Merge เข้า `main` แล้ว และ issue ปิดอัตโนมัติผ่าน `Closes #`
