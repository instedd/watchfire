class ChannelsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :build_channel, only: [:new, :create]
  before_filter :find_channel, only: [:edit, :update, :destroy]
  before_filter :add_channels_breadcrumb, :only => [:index, :new, :edit, :create, :update]

  def index
  end

  def new
    add_breadcrumb 'New', new_channel_path(:kind => params[:kind])
  end

  def create
    if save_channel
      redirect_to channels_path, notice: 'Channel created'
    else
      add_breadcrumb 'New', new_channel_path(:kind => params[:kind])
      render 'new'
    end
  end

  def edit
    add_breadcrumb @pigeon_channel.name, edit_channel_path(@pigeon_channel)
  end

  def update
    if save_channel
      redirect_to channels_path, notice: 'Channel updated'
    else
      add_breadcrumb @pigeon_channel.name, edit_channel_path(@pigeon_channel)
      render 'edit'
    end
  end

  def destroy
    @pigeon_channel.destroy
    if @pigeon_channel.destroyed?
      @channel.destroy
      redirect_to channels_path, notice: 'Channel deleted'
    else
      redirect_to channels_path, alert: @pigeon_channel.errors.full_messages.join
    end
  end

  private

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def build_channel
    type, kind = params[:kind].split('/')
    channel_type = Pigeon::Channel.find_type(type)

    @channel = channel_type.new kind: kind
    @channel.generate_name!
    @channel_schema = @channel.schema
    not_found if @channel_schema.nil?

    @pigeon_channel = PigeonChannel.new
    @pigeon_channel.channel_type = @channel.type
    @pigeon_channel.organization = current_organization
    @pigeon_channel.pigeon_name = @channel.name
  end

  def find_channel
    @pigeon_channel = PigeonChannel.find(params[:id])
    @channel = Pigeon::Channel.find_type(@pigeon_channel.channel_type).find(@pigeon_channel.pigeon_name)
    @channel_schema = @channel.schema
  end

  def save_channel
    @pigeon_channel.assign_attributes params[:pigeon_channel]
    @channel.assign_attributes params[:channel_data]
    begin
      if @channel.type == :verboice
        @pigeon_channel.limit = @channel.limit
      end
      @pigeon_channel.transaction do
        @pigeon_channel.save!
        @channel.save!
      end
      true
    rescue ActiveRecord::RecordInvalid, Pigeon::ChannelInvalid
      false
    end
  end

  def add_channels_breadcrumb
    add_breadcrumb "#{current_organization.name}", organizations_path if current_organization
    add_breadcrumb "Channels", :channels_path
  end
end
