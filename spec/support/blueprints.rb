require 'machinist/active_record'

Volunteer.blueprint do
  name { _name }
  lat { _lat }
  lng { _lng }
  address { _address }
  voice_number { _phone_number }
  sms_number { _phone_number }
end

Candidate.blueprint do
  mission
  volunteer
end

Mission.blueprint do
  req_vols { rand(6) + 5 }
  lat { _lat }
  lng { _lng }
  address { _address }
end

def _name
  Faker::Name.name
end

def _address
   Faker::Address.country
end

def _phone_number
  Faker::PhoneNumber.phone_number
end

def _lat
  rand * 180 - 90
end

def _lng
  rand * 360 - 180
end