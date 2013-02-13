class ChannelsController < ApplicationController
  before_filter :authenticate_user!

  def index
  end

  def create
  #   Pigeon.create_channel(params) do |channel|
  #     if channel.nuntium?
  #       channel.name = 'new_email_channel'
  #       channel.restrictions = [{'name' => 'foo', 'value' => 'bar'}]
  #     else
  #     end
  #   end
  # rescue Pigeon::Exception => ex
  #   @pigeon_exception = ex
  #   render :index
  end
end