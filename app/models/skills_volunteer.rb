class SkillsVolunteer < ActiveRecord::Base
  belongs_to :skill
  belongs_to :volunteer
end
