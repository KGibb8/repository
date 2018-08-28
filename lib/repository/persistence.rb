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
        case self.persistence_strategy
        when :yaml
          if File.exist? "#{self.name}.yml"
            self.records = YAML.load_file(self.name)
          end
        when :csv
          csv_info = nil
          if File.exist? "#{self.name}.csv"
            File.open("#{self.name}.csv", "r") { |file| csv_info = file.read  }

            column_mappings = nil
            CSV.parse(csv_info) do |row|
              if column_mappings.nil?
                column_mappings = row
              else
                params = Hash.new
                column_mappings.each_with_index do |column, index|
                  params[column.to_sym] = row[index]
                end
                self.create(params)
              end
            end
          end
        end
      end

      def persist
        success = nil
        case persistence_strategy ||= :yaml
        when :yaml
          storage = if File.exists?("#{self.name}.yml")
                      File.open("#{self.name}.yml", "w")
                    else
                      File.new("#{self.name}.yml", "w")
                    end

          success = storage.write(records.to_yaml)
        when :csv
          storage = if File.exists?("#{self.name}.csv")
                      File.open("#{self.name}.csv", "w")
                    else
                      File.new("#{self.name}.csv", "w")
                    end

          success = storage.write(records.to_csv)
        when :json
          storage = if File.exists?("#{self.name}.json")
                      File.open("#{self.name}.json", "w")
                    else
                      File.new("#{self.name}.json", "w")
                    end

          success = storage.write(records.to_json)
        else
          raise PersistenceError, "No persistence strategy set"
        end

        success
      end

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
