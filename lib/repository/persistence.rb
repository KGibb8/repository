# frozen_string_literal: true

require "json"
require "yaml"
require "csv"

module Repository
  module Persistence
    PersistenceError = Class.new(StandardError)

    PERSISTENCE_STRATEGIES = [:yaml, :csv, :psql, :json]

    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    module ClassMethods
      attr_writer :records

      def set_persistence_strategy(strategy)
        raise PersistenceError, "unsupported persistence strategy" unless PERSISTENCE_STRATEGIES.include? strategy
        self.persistence_strategy = strategy
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
        when :psql
          raise PersistenceError, "psql currently unsupported"
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
        when :psql
          raise PersistenceError, "psql currently unsupported"
        end

        success
      end

      def records
        @records ||= []
      end

      private

      attr_accessor :persistence_strategy
    end
  end
end
