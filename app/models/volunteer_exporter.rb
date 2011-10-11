require 'csv'

class VolunteerExporter
	
	def self.export mission
		CSV.generate do |csv|
			csv << headers
			mission.candidates.each do |candidate|
				volunteer = candidate.volunteer
				csv << [volunteer.name, volunteer.voice_number, volunteer.sms_number, volunteer.address, candidate.status.to_s]
			end
		end
	end
	
	private
	
	def self.headers
		["Name", "Voice Number", "SMS Number", "Address", "Status"]
	end
	
end