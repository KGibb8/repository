# frozen_string_literal: true

require "json"
require "yaml"
require "csv"

module Repository
  module Persistence
    PersistenceError = Class.new(StandardError)

    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # don't belong here...
    module InstanceMethods
      def destroy
        before_destroy_callbacks = self.class.instance_variable_get("@before_destroy_callbacks") || []
        before_destroy_callbacks.each { |callback| callback.(self) }

        index = self.class.records.index(self)

        if self.class.records.delete_at(index)
          after_destroy_callbacks = self.class.instance_variable_get("@after_destroy_callbacks") || []
          after_destroy_callbacks.each { |callback| callback.(self) }
          self.class.persist
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
          success = self.class.persist
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
      attr_accessor :persistence_strategy
      attr_writer :records

      # doesnt belong here...
      def create(params)
        record = new(params)
        return record unless record.valid?
        @before_create_callbacks ||= []
        @before_create_callbacks.each { |callback| callback.(record) }
        record.save
        @after_create_callbacks ||= []
        @after_create_callbacks.each { |callback| callback.(record) }
        record
      end

      def load
        case self.persistence_strategy ||= :yaml
        when :yaml
          if File.exist? "#{self.name}.yml"
            self.records = YAML.load_file(self.name)
          end
        when :csv
          if File.exist? "#{self.name}.csv"
            table = CSV::Table.new(File.open "#{self.name}.csv")
            columns = table.first.split(", ").map(&:chomp)

            self.records = table.by_row.map.with_index do |row, index|
              attributes = row.split(", ").map(&:chomp)
              params = Hash[columns.zip(attributes)]
              self.create(params)
            end
          end
        when :json
          if File.exist? "#{self.name}.json"
            json = File.open("#{self.name}.json", "r").read
            self.records = json.map { |hash| self.create(hash) }
          end
        else
          raise PersistenceError, "unsupported persistence strategy"
        end

        !self.records.nil?
      end

      def persist
        success = nil
        case persistence_strategy ||= :yaml
        when :yaml
          storage = if File.exist? "#{self.name}.yml"
                      File.open "#{self.name}.yml", "w"
                    else
                      File.new "#{self.name}.yml", "w"
                    end

          success = storage.write(records.to_yaml)
        when :csv
          storage = if File.exist? "#{self.name}.csv"
                      File.open "#{self.name}.csv", "w"
                    else
                      File.new "#{self.name}.csv", "w"
                    end

          success = storage.write(records.to_csv)
        when :json
          storage = if File.exist? "#{self.name}.json"
                      File.open "#{self.name}.json", "w"
                    else
                      File.new "#{self.name}.json", "w"
                    end

          success = storage.write(records.to_json)
        else
          raise PersistenceError, "unsupported persistence strategy"
        end

        success
      end

      # don't belong here...
      def update_all(params)
        records.each { record| record.update(params) }
      end

      def destroy_all
        records.clear
      end

      def records
        @records ||= []
      end
    end
  end
end
