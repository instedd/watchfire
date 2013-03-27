class ChannelsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :build_channel, only: [:new, :create]
  before_filter :find_channel, only: [:edit, :update, :destroy]

  def index
  end

  def new
  end

  def create
    if save_channel
      redirect_to channels_path, notice: 'Channel created'
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if save_channel
      redirect_to channels_path, notice: 'Channel updated'
    else
      render 'edit'
    end
  end

  def destroy
    @channel.destroy
    @pigeon_channel.destroy
    redirect_to channels_path, notice: 'Channel deleted'
  end

  private

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def build_channel
    @channel_kind = Pigeon::ChannelKind.from_type_and_kind(params[:kind])
    not_found if @channel_kind.nil?

    @channel = @channel_kind.build_channel
    @pigeon_channel = PigeonChannel.new
    @pigeon_channel.channel_type = @channel_kind.type
    @pigeon_channel.organization = current_organization
    @pigeon_channel.pigeon_name = @channel.name
  end

  def find_channel
    @pigeon_channel = PigeonChannel.find(params[:id])
    @channel = Pigeon::Channel.from_type(@pigeon_channel.channel_type).find(@pigeon_channel.pigeon_name)
    @channel_kind = @channel.channel_kind
  end

  def save_channel
    @pigeon_channel.assign_attributes params[:pigeon_channel]
    @channel.assign_attributes params[:channel_data]
    begin
      @pigeon_channel.transaction do
        @pigeon_channel.save!
        @channel.save!
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
