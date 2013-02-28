class MigrateChannels < ActiveRecord::Migration
	class Volunteer < ActiveRecord::Base
	end
	class Channel  < ActiveRecord::Base
		belongs_to :volunteer
	end
	class ::SmsChannel < Channel
	end
	class ::VoiceChannel < Channel
	end
	
  def self.up
		Volunteer.all.each do |volunteer|
			unless volunteer.sms_number.blank?
				SmsChannel.create! :volunteer => volunteer, :address => volunteer.sms_number
			end
			unless volunteer.voice_number.blank?
				VoiceChannel.create! :volunteer => volunteer, :address => volunteer.voice_number
			end
		end
	
		remove_column :volunteers, :sms_number
		remove_column :volunteers, :voice_number
  end

  def self.down
		add_column :volunteers, :voice_number, :string
		add_column :volunteers, :sms_number, :string
		
		Volunteer.all.each do |volunteer|
			sms = SmsChannel.where(:volunteer_id => volunteer.id).first
			voice = VoiceChannel.where(:volunteer_id => volunteer.id).first
			volunteer.sms_number = sms.address if sms
			volunteer.voice_number = voice.address if voice
			volunteer.save! if sms || voice
		end
  end
end