# frozen_string_literal: true

module Repository
  module Query
    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
      def destroy
        before_destroy_callbacks = self.class.instance_variable_get("@before_destroy_callbacks") || []
        before_destroy_callbacks.each { |callback| callback.(self) }

        index = self.class.records.index(self)

        if self.class.records.delete_at(index)
          after_destroy_callbacks = self.class.instance_variable_get("@after_destroy_callbacks") || []
          after_destroy_callbacks.each { |callback| callback.(self) }
          self.class.__send__(:persist)
        end

        self
      end

      def update(params)
        before_update_callbacks = self.class.instance_variable_get("@before_update_callbacks") || []
        before_update_callbacks.each { |callback| callback.(self) }

        params.each do |k, v|
          self.send("#{k.to_sym}", v)
        end

        self.save

        after_update_callbacks = self.class.instance_variable_get("@after_update_callbacks") || []
        after_update_callbacks.each { |callback| callback.(self) }

        self
      end

      def save
        success = nil

        before_save_callbacks = self.class.instance_variable_get("@before_save_callbacks") || []
        before_save_callbacks.each { |callback| callback.(self) }

        return false unless self.valid?

        unless success = self.persisted?
          self.class.records << self
          success = self.class.__send__(:persist)
        end

        after_save_callbacks = self.class.instance_variable_get("@after_save_callbacks") || []
        after_save_callbacks.each { |callback| callback.(self) } if success

        success
      end

      def persisted?
        !self.class.records.index(self).nil?
      end
    end

    module ClassMethods
      def create(params)
        record = new(params)
        return record unless record.valid?
        @before_create_callbacks ||= []
        @before_create_callbacks.each { |callback| callback.(record) }
        return false unless record.save
        @after_create_callbacks ||= []
        @after_create_callbacks.each { |callback| callback.(record) }
        record
      end

      def all
        collection
      end

      def where(params)
        collection.where(params)
      end

      def find_by(params)
        collection.find_by(params)
      end

      def update_all(params)
        records.each { record| record.update(params) }
      end

      def destroy_all
        records.clear
      end

      private

      def collection
        Repository::Collection.new(records)
      end
    end
  end
end
