require 'spec_helper'

describe "SchedulerAdvisor" do
  before(:each) do
    @advisor = SchedulerAdvisor.new nil
    SchedulerAdvisor.stubs(:open).yields(@advisor)
  end

  after(:each) do
    SchedulerAdvisor.unstub(:open)
  end

  it "should send advice for any method missing" do
    @advisor.expects(:send_data)
    SchedulerAdvisor.foo
  end

  it "should send advice through the advice method" do
    @advisor.expects(:send_data)
    SchedulerAdvisor.advice 'foo'
  end

  it "should send arguments encoded as new-line terminated JSON" do
    @advisor.expects(:send_data).with(["foo", 42, "bar"].to_json + "\n")
    SchedulerAdvisor.foo 42, 'bar'
  end

  it "should use ActiveModel conversion to send parameters" do
    org = Organization.make!
    
    @advisor.expects(:send_data)
      .with(["new_organization", org.to_param].to_json + "\n")
    SchedulerAdvisor.new_organization org
  end
end

