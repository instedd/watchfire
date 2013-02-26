require 'spec_helper'

describe ImportViewModel do
  before(:each) do
    @view_model = ImportViewModel.new(Organization.make!)
  end

  it "initializes volunteers array" do
    @view_model.size.should eq(0)
  end
end

