# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Sets `order.payment_state` based on payment validity, order state,
      # and outstanding balance.
      class AssignPaymentState
        def call(context)
          order = context.order
          order.payment_state = determine_payment_state(order)

          yield context
        end

        private

        def determine_payment_state(order)
          if order.payments.present? && order.payments.valid.empty? && order.outstanding_balance != 0
            "failed"
          elsif order.state == "canceled" && order.payment_total.zero?
            "void"
          elsif order.outstanding_balance > 0
            "balance_due"
          elsif order.outstanding_balance < 0
            "credit_owed"
          else
            "paid"
          end
        end
      end
    end
  end
end
