FactoryBot.define do
  factory :product_review do
    product factory: %i[product pending_review]
    reviewer factory: %i[user admin]
    decision { :approved }

    trait :rejected do
      decision { :rejected }
      reason { "รูปหน้าปัดเบลอ" }
    end
  end
end
