module Settings
  class PaymentsController < BaseController
    before_action :require_store!

    def show
    end

    def update
      if @store.update(payment_params)
        redirect_to settings_payments_path, notice: "Payment options updated."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def payment_params
      params.expect(store: [:venmo_handle, :paypal_url])
    end
  end
end
