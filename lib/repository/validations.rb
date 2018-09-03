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
        self.class.__send__(:perform_validations, self)
        self.errors.blank?
      end
    end

    module ClassMethods
      VALIDATES_OPTIONS = [:presence, :uniqueness, :format]

      def validate(method, options = {}, &block)
        to_call = block_given? ? block : Proc.new { |record| record.send(method) }
        store_callback(to_call, method)
      end

      def validates(attribute, options = {})
        options.each do |option, value|
          raise ArgumentError, "unknown validation" unless VALIDATES_OPTIONS.include? option

          to_call = Proc.new do |record|
            case option
            when :presence
              if record.send(attribute).nil?
                record.errors.add(attribute, "#{attribute}")
              end
            when :uniqueness
              attribute_value = record.send(attribute)
              unless attribute_value.nil?
                others = self.all.where(option => attribute_value)
                unless others.select { |r| r.object_id == record.object_id }.empty?
                  record.errors.add(attribute, "#{attribute} is not unique")
                end
              end
            when :format
              if regex = option[:with]
                unless record.send(attribute).match(regex)
                  record.errors.add(attribute, "#{attribute} must match format #{regex}")
                end
              else
                raise ArgumentError, "provide a hash with a format scope"
              end
            end
          end

          store_callback(to_call, attribute)
        end
      end

      def validates_presence_of(attribute)
        to_call = Proc.new do |record|
          if record.send(attribute).blank?
            record.errors.add(attribute, "#{attribute}")
          end
        end
        store_callback(to_call, attribute)
      end

      def validates_uniqueness_of(attribute)
        to_call = Proc.new do |record|
          attribute_value = record.send(attribute)
          unless attribute_value.nil?
            others = self.all.where(option => attribute_value)
            unless others.select { |r| r.object_id == record.object_id }.empty?
              record.errors.add(attribute, "#{attribute} is not unique")
            end
          end
        end
        store_callback(to_call, attribute)
      end

      def validates_format_of(attribute, options = {})
        to_call = Proc.new do |record|
          if regex = options[:with]
            unless record.send(attribute).match(regex)
              record.errors.add(attribute, "#{attribute} must match format #{regex}")
            end
          else
            raise ArgumentError, "provide a hash with a format scope"
          end
        end
        store_callback(to_call, attribute)
      end

      private

      def perform_validations (record)
        @before_validation_callbacks ||= []
        @before_validation_callbacks.each { |callback| callback.(record) }

        @errors = Repository::Errors.new(record)

        setup_callbacks
        @validation_callbacks.each do |callback|
          callback.(record)
        end

        @errors.uniq!

        @after_validation_callbacks ||= []
        @after_validation_callbacks.each { |callback| callback.call(record) }
      end

      def setup_callbacks
        @validation_callbacks ||= []
      end

      def store_callback(to_call, method_name)
        setup_callbacks
        callback = Repository::Callbacks::Callback.new(to_call, method_name)
        @validation_callbacks << callback
      end
    end
  end
end
