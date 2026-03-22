class Stores::EventProductsController < ApplicationController
  before_action :require_authentication!
  before_action :set_store
  before_action :set_event_product, only: [:edit, :update, :destroy]
  before_action :set_event
  before_action :require_store_owner!

  def new
    @event_product = @event.event_products.new
  end

  def create
    @event_product = @event.event_products.new(event_product_params)

    if @event_product.save
      redirect_to event_path(@event), notice: "Product added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event_product.update(event_product_params)
      redirect_to event_path(@event), notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event_product.destroy
    redirect_to event_path(@event), notice: "Product removed."
  end

  private

  def set_store
    @store = current_user.store
  end

  # Load @event_product only for shallow routes
  def set_event_product
    return unless params[:id]
    @event_product = EventProduct.find(params[:id])
  end

  # Derive @event:
  # - From nested routes → params[:event_id]
  # - From shallow routes → @event_product.event
  def set_event
    @event = if params[:event_id]
      @store.events.find(params[:event_id])
    else
      @event_product.event
    end
  end

  def require_store_owner!
    return if current_user == @store.user
    redirect_to event_path(@event), alert: "Not allowed."
  end

  def event_product_params
    params.require(:event_product)
      .permit(:name, :quantity, :description, :price, :image)
  end
end
