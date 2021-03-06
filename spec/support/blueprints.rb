require 'machinist/active_record'

Organization.blueprint do
  name { "#{_name}-#{sn}" }
end

Volunteer.blueprint do
  organization { Organization.make! }
  name { _name }
  lat { _lat }
  lng { _lng }
  address { _address }
	voice_channels { [VoiceChannel.make] }
	sms_channels { [SmsChannel.make] }
end

Candidate.blueprint do
  mission { Mission.make! }
  volunteer { Volunteer.make! }
end

Mission.blueprint do
  organization { Organization.make! }
  user { User.make! }
  name { _name }
  lat { _lat }
  lng { _lng }
  address { _address }
  city { _city }
  mission_skills { [MissionSkill.make] }
end

Skill.blueprint do
  organization { Organization.make! }
  name { _name }
end

MissionSkill.blueprint do
end

User.blueprint do
  email { _email }
  password { _password }
  confirmed_at { Time.now }
end

VoiceChannel.blueprint do
	address { _phone_number }
end

SmsChannel.blueprint do
	address { _phone_number }
end

CurrentCall.blueprint do
  session_id { _guid }
  voice_number { _phone_number }
  candidate { Candidate.make! }
  pigeon_channel { PigeonChannel.make!(:verboice) }
end

PigeonChannel.blueprint do
  organization { Organization.make! }
  name { _name }
  pigeon_name { _name }
end

PigeonChannel.blueprint(:verboice) do
  channel_type { :verboice }
end

PigeonChannel.blueprint(:nuntium) do
  channel_type { :nuntium }
end

def _name
  Faker::Name.name
end

def _address
   Faker::Address.country
end

def _city
   Faker::Address.city
end

def _email
  Faker::Internet.email
end

def _password
  rand(36**8).to_s(36).ljust(8, '0')
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

def _guid
  (1..10).map{ ('a'..'z').to_a.sample }.join
end
