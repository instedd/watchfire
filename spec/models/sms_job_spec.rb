require 'spec_helper'

describe SmsJob do
  pending "should send sms to volunteer"
  
  pending "should not send sms if status is not pending"
  
  pending "should not send sms if retries > max_retries"
  
  pending "should set unresponsive status if retries > max_retries"
  
  pending "should not increase retries if sms wasn't delivered"
  
  pending "should increase retries if sms was successful"
end