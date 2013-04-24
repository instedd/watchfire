require 'drb/drb'

SchedulerAdvisor.advisor = DRb::DRbObject.new_with_uri(SchedulerAdvisor.uri)

