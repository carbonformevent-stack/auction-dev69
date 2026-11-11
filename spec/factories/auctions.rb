FactoryBot.define do
  factory :auction do
    product factory: %i[product approved]
    created_by factory: %i[user admin]
    auction_type { :fpsba }
    starting_price { product.starting_price }
    starts_at { 1.day.from_now.change(min: 0) }
    ends_at { starts_at + 3.days }

    trait :running do
      status { :running }
      starts_at { 1.hour.ago }
      to_create { |auction| auction.save!(validate: false) } # เริ่มไปแล้ว — ข้าม validation "เวลาเริ่มต้องเป็นอนาคต"
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
