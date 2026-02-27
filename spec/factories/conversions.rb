FactoryBot.define do
  factory :conversion do
    user { nil }
    tool_name { "MyString" }
    status { 1 }
    error_message { "MyText" }
    processing_time { 1.5 }
  end
end
