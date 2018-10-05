# frozen_string_literal: true

require "json"
require "yaml"
require "csv"

module Repository
  module Persistence
    PersistenceError = Class.new(StandardError)

    PERSISTENCE_STRATEGIES = [:yaml, :csv, :psql, :json]

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      attr_reader :persistence_strategy
      attr_writer :records

      def set_persistence_strategy(strategy)
        raise PersistenceError, "unsupported persistence strategy" unless PERSISTENCE_STRATEGIES.include? strategy
        self.persistence_strategy = strategy
      end

      def load
        case self.persistence_strategy ||= :yaml
        when :yaml
          if File.exist? "#{self.name.underscore}.yml"
            self.records = YAML.load_file("#{self.name.underscore}.yml")
          end
        when :csv
          if File.exist? "#{self.name.underscore}.csv"
            table = CSV::Table.new(File.open "#{self.name.underscore}.csv")
            columns = table.first.split(", ").map(&:chomp)

            self.records = table.by_row.map.with_index do |row, index|
              attributes = row.split(", ").map(&:chomp)
              params = Hash[columns.zip(attributes)]
              self.create(params)
            end
          end
        when :json
          if File.exist? "#{self.name.underscore}.json"
            json = JSON.parse(File.open("#{self.name.underscore}.json", "r").read)
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
          storage = if File.exist? "#{self.name.underscore}.yml"
                      File.open "#{self.name.underscore}.yml", "w"
                    else
                      File.new "#{self.name.underscore}.yml", "w"
                    end

          success = storage.write(records.to_yaml)
        when :csv
          storage = if File.exist? "#{self.name.underscore}.csv"
                      File.open "#{self.name.underscore}.csv", "w"
                    else
                      File.new "#{self.name.underscore}.csv", "w"
                    end

          success = storage.write(records.to_csv)
        when :json
          storage = if File.exist? "#{self.name.underscore}.json"
                      File.open "#{self.name.underscore}.json", "w"
                    else
                      File.new "#{self.name.underscore}.json", "w"
                    end

          success = storage.write(JSON.dump(records))
        when :psql
          raise PersistenceError, "psql currently unsupported"
        end

        success
      end

      def records
        @records ||= []
      end

      private

      attr_writer :persistence_strategy
    end
  end
end
