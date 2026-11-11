FactoryBot.define do
  factory :product do
    seller factory: :user
    category { :watch }
    starting_price { 1000 }
    sequence(:title) { |n| "นาฬิกาพกโบราณ #{n}" }
    description { "นาฬิกาพกไขลาน ตัวเรือนเงินแท้ ยังเดินได้ปกติ" }
    desired_duration_minutes { 1440 }

    trait :with_image do
      after(:build) do |product|
        product.images.attach(io: Rails.root.join("spec/fixtures/files/image.jpg").open, filename: "image.jpg")
      end
    end

    trait :pending_review do
      with_image
      status { :pending_review }
      submitted_at { Time.current }
    end

    trait :approved do
      with_image
      status { :approved }
      submitted_at { 1.hour.ago }
    end

    trait :rejected do
      with_image
      status { :rejected }
      submitted_at { 1.hour.ago }
    end
  end
end
