# frozen_string_literal: true

module Repository
  module Callbacks
    PREFIXES = [:before, :after]
    SUFFIXES = [:save, :create, :update, :validation, :destroy]
    COMBINATIONS = PREFIXES.product(SUFFIXES)
                           .map {|combo| combo.map(&:to_s).join("_") }
                           .map(&:to_sym)

    def self.included(base)
      base.extend(ClassMethods)
    end

    class Callback
      attr_reader :method_name

      def initialize(to_call:, method_name:)
        @to_call = to_call
        @method_name = method_name
      end

      def call(record)
        to_call.(record)
      end

      private

      attr_reader :to_call
    end

    module ClassMethods
      COMBINATIONS.each do |callback_method_sym|
        define_method callback_method_sym do |method, options = {}, &block|
          variable_name = "@#{callback_method_sym}_callbacks"
          callbacks = instance_variable_get(variable_name)
          callbacks = instance_variable_set(variable_name, []) unless callbacks

          callbacks << Callback.new(
            to_call: block_given? ? block : Proc.new { |record| record.send(method) },
            method_name: method
          )
        end
      end
    end
  end
end
