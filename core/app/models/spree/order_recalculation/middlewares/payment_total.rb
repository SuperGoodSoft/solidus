# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Sets `order.payment_total` to the sum of completed payments minus
      # their refunds.
      class PaymentTotal
        def call(context)
          order = context.order
          order.payment_total =
            order.payments.completed.includes(:refunds).sum { |payment|
              payment.amount - payment.refunds.sum(:amount)
            }

          yield context
        end
      end
    end
  end
end
