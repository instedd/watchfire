module MissionsHelper
  def progress_percentage mission
    "width: #{mission.progress * 100}%;"
  end
end
