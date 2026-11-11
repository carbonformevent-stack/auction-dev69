# Roadmap

> Sprint ละ 1 วัน เริ่ม Sprint 0 วันที่ 2026-11-11 — รายละเอียดและ issue อยู่ที่ GitHub → Issues → Milestones
> M0–M3 = เส้นทางสู่ **Release v0.1 Beta** (committed) · M4 ขึ้นไป = tentative **ลำดับปรับใหม่ทุก Sprint Review**

| Milestone | วันที่ | เป้าหมาย | เกณฑ์สำเร็จ |
|---|---|---|---|
| M0 Groundwork | 2026-11-11 | GitHub, standard, CI, Rails + SQLite, Auth (Keycloak) + Role (user/admin) | ทีม merge PR แรกผ่าน CI ได้ |
| M1 ลงสินค้าและอนุมัติ | 2026-11-12 | ผู้ขายลงสินค้า, Admin approve/reject | สินค้าเดินครบทุกสถานะตั้งแต่ draft ถึง approved |
| M2 จัดและประมูล FPSBA | 2026-11-13 | Admin สร้างการประมูล, ผู้ใช้เสนอราคาแบบปิดผนึก | เสนอราคาได้ตามกติกาครบทุกข้อ |
| M3 ปิดการประมูลและขึ้นระบบ | 2026-11-14 | ปิดอัตโนมัติ, ประกาศผู้ชนะ, แจ้งเตือนอีเมล, deploy production, analytics | Release v0.1 Beta มีการประมูลจริงจบอย่างน้อย 1 รอบ |
| M4 Feedback & Hardening | — | แก้ปัญหาจาก Beta, UX, security, performance | (tentative) |
| M5 ชำระเงินและส่งมอบ | — | Payment gateway, มัดจำ, ติดตามการจัดส่ง | (tentative) |
| M6 วิธีประมูลเพิ่มเติม | — | English, Vickrey, Dutch | (tentative) |
| M7 ความน่าเชื่อถือ | — | KYC, รีวิวผู้ขาย, ข้อพิพาท, ตรวจสอบใบรับรอง | (tentative) |
| M8 Engagement & Scale | — | Watchlist, real-time notification, ค้นหา/กรอง, มือถือ | (tentative) |

Data model และกติกาการประมูล: [architecture/auction-design.md](architecture/auction-design.md)
