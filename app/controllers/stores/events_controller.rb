class Stores::EventsController < ApplicationController
  before_action :require_authentication!
  before_action :set_store
  before_action :set_event, only: [:show, :edit, :update, :destroy, :publish, :duplicate, :prep]

  def index
    @events = @store.events.order(pickup_at: :asc)
  end

  def show
    @orders = @event.orders.includes(user: [], order_items: [:event_product]).order(created_at: :asc)
  end

  def new
    @event = @store.events.new
  end

  def create
    @event = @store.events.new(event_params)

    if @event.save
      redirect_to event_path(@event), notice: "Event created (Draft)."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def prep
    render layout: false
  end

  def duplicate
    new_event = @event.spawn_next_event
    redirect_to edit_event_path(new_event), notice: "Event duplicated. Please verify dates."
  end

  def publish
    if current_user.at_event_limit?
      return redirect_to billing_upgrade_path, alert: "You've reached your free plan limit of #{User::FREE_EVENT_LIMIT} active #{"event".pluralize(User::FREE_EVENT_LIMIT)}. Upgrade to Pro for unlimited events."
    end

    @event.publish!

    @store.notifications.includes(:user).find_each do |notification|
      StoreMailer.new_event(@store, @event, notification).deliver_later
    end

    notice = "Event published!"
    notice += " Next draft spawned for repeating bake." if @event.repeat_interval.present? && !@event.no_repeat?
    redirect_to event_path(@event), notice: notice
  rescue ActiveRecord::RecordInvalid
    redirect_to event_path(@event), alert: @event.errors.full_messages.to_sentence
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @event.destroy
      redirect_to store_events_path, notice: "Event deleted."
    else
      redirect_to event_path(@event), alert: "Cannot delete event: #{@event.errors.full_messages.to_sentence}"
    end
  end

  private

  def set_store
    @store = current_user.store
  end

  def set_event
    @event = @store.events.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :name,
      :description,
      :orders_close_at,
      :pickup_at,
      :repeat_interval,
      :pickup_address
    )
  end
end
