require 'factory_girl'

FactoryGirl.define do
  factory :user do
    name 'Test User'
    email 'user@test.com'
    password 'please'
  end
end
