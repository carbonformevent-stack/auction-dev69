# ชื่อ cookie ตั้งต้นของ Rails มาจากชื่อ module ของแอป (เดิม Auction → "_auction_session")
# ล็อกไว้ตามเดิม เพื่อไม่ให้ผู้ใช้ที่ login อยู่หลุดเมื่อเปลี่ยนชื่อ module เป็น AuctionDev69
Rails.application.config.session_store :cookie_store, key: "_auction_session"
