require 'spec_helper'

describe Skill do
  before :each do
    @skill = Skill.new
  end
  
  it "should have a name" do
    @skill.name = nil
    @skill.valid?.should be_false
    @skill.name = ''
    @skill.valid?.should be_false
  end
  
  it "should be invalid with 'volunteer' or 'volunteers' as name" do
    @skill.name = 'volunteer'
    @skill.valid?.should be_false
    @skill.name = 'volunteers'
    @skill.valid?.should be_false
  end
  
end
