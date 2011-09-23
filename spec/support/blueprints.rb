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
  mission { Mission.make! }
  volunteer { Volunteer.make! }
end

Mission.blueprint do
  name { _name }
  req_vols { rand(6) + 5 }
  lat { _lat }
  lng { _lng }
  address { _address }
end

MissionJob.blueprint do
  mission { Mission.make! }
  job { Delayed::Job.create! }
end

Skill.blueprint do
  name { _name }
end

User.blueprint do
  email { _email }
  password { _password }
end

def _name
  Faker::Name.name
end

def _address
   Faker::Address.country
end

def _email
  Faker::Internet.email
end

def _password
  rand(36**8).to_s(36)
end

def _phone_number
  # Faker::PhoneNumber.phone_number
  rand(10000)
end

def _lat
  rand * 180 - 90
end

def _lng
  rand * 360 - 180
end