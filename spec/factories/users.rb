FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    plan { :free }
    conversions_count { 0 }
    subscription_status { :inactive }
  end
end
