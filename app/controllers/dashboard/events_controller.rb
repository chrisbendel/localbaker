module Dashboard
  class EventsController < BaseController
    before_action :set_event, only: [:show, :edit, :update, :destroy, :publish, :duplicate, :prep]
    before_action :ensure_event_not_past!, only: [:edit, :update, :destroy, :publish]

    def index
      @events = @store.events.order(pickup_starts_at: :desc)
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

      if current_user.pro?
        @store.notifications.includes(:user).find_each do |notification|
          StoreMailer.new_event(@store, @event, notification).deliver_later
        end
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
        redirect_to dashboard_events_path, notice: "Event deleted."
      else
        redirect_to event_path(@event), alert: "Cannot delete event: #{@event.errors.full_messages.to_sentence}"
      end
    end

    private

    def set_event
      @event = @store.events.find(params[:id])
    end

    def ensure_event_not_past!
      if @event.past?
        redirect_to event_path(@event), alert: "Past events cannot be edited."
      end
    end

    def event_params
      permitted = [:name, :description, :orders_close_at, :pickup_starts_at, :pickup_ends_at, :repeat_interval, :pickup_address]
      permitted << :delivery_enabled if current_user.pro?
      p = params.require(:event).permit(*permitted)

      # date_field submits a bare date string (no time). Coerce to end of day so
      # orders stay open through the full date the baker selected, not just midnight UTC.
      if p[:orders_close_at].present?
        p[:orders_close_at] = Date.parse(p[:orders_close_at]).end_of_day
      end

      p
    end
  end
end
