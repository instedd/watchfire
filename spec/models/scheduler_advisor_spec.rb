require 'spec_helper'

describe "SchedulerAdvisor" do
  before(:each) do
    @advisor = mock
    @old_advisor = SchedulerAdvisor.advisor
    SchedulerAdvisor.advisor = @advisor
  end

  after(:each) do
    SchedulerAdvisor.advisor = @old_advisor
  end

  it "should send advice for any method missing" do
    @advisor.expects(:foo)
    SchedulerAdvisor.foo
  end

  it "should send advice through the advice method" do
    @advisor.expects(:foo)
    SchedulerAdvisor.advice 'foo'
  end

  it "should send arguments" do
    @advisor.expects(:foo).with(42, 'bar')
    SchedulerAdvisor.foo 42, 'bar'
  end

  it "should use ActiveModel conversion to send parameters" do
    org = Organization.make!
    
    @advisor.expects(:new_organization).with(org.to_param)
    SchedulerAdvisor.new_organization org
  end
end

