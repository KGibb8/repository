# frozen_string_literal: true

module Repository
  module Validations
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module InstanceMethods
      def errors
        self.class.instance_variable_get("@errors") ||
          Repository::Errors.new(self)
      end

      def valid?
        self.class.perform(self)
        self.errors.blank?
      end
    end

    module ClassMethods
      VALIDATES_OPTIONS = [:presence, :uniqueness]

      def validate(method, options = {}, &block)
        @validation_callbacks ||= []
        @validation_callbacks << Repository::Callbacks::Callback.new(
          to_call: block_given? ? block : Proc.new { |record| record.send(method) },
          method_name: method
        )
      end

      def validates(attribute, options = {})
        @validation_callbacks ||= []

        to_call = Proc.new do |record|
          is_valid = true # innocent until proven guilty

          if options[:presence]
            is_valid = record&.(attribute) ? true : false
          end

          if options[:uniqueness]
            attribute_value = record&.(attribute)
            unless is_valid = attribute_value.nil?
              others = self.all.where(name: recordname)
              is_valid = others.select { |r| r.object_id == record.object_id }.empty?
            end
          end

          if format = options[:format]
            if regex = format[:with]
              is_valid = attribute.match(regex) ? true : false
            else
              raise ArgumentError, "provide a hash with a format scope"
            end
          end

          is_valid
        end

        @validation_callbacks << Repository::Callbacks::Callback.new(
          to_call: to_call,
          method_name: attribute
        )
      end

      def perform (record)
        @before_validation_callbacks ||= []
        @before_validation_callbacks.each { |callback| callback.(record) }

        @errors = Repository::Errors.new(record)

        @validation_callbacks ||= []
        @validation_callbacks.each do |callback|
          callback.(record)
        end

        @errors.uniq!

        @after_validation_callbacks ||= []
        @after_validation_callbacks.each { |callback| callback.call(record) }
      end
    end
  end
end
