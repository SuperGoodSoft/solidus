# frozen_string_literal: true

module Spree
  module OrderRecalculation
    # Folds a middleware list into a nested chain of `call(ctx, &inner)`
    # invocations and runs it against the given context.
    module Runner
      def self.call(middlewares, context)
        chain = middlewares.to_a.reverse.reduce(->(_ctx) {}) { |inner, klass|
          ->(ctx) { klass.new.call(ctx, &inner) }
        }

        chain.call(context)
      end
    end
  end
end
