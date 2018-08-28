# frozen_string_literal: true

module Repository
  class Collection
    include Enumerable

    # .first? comes with Enumerable
    ACCESSORS = [:second, :third, :fourth, :fifth, :sixth, :seventh, :eighth, :ninth, :tenth]

    ACCESSORS.each_with_index do |method_sym, i|
      define_method method_sym do
        self[i]
      end
    end

    def initialize(records)
      @records = records
    end

    def all
      records
    end

    def each
      if block_given?
        self.records.each { |record| yield(record) }
      else
        self.records.each
      end
    end

    def where(params)
      response = nil
      params.each do |k, v|
        if response.nil?
          response = records.select { |record| record.send(k) == v }
        else
          response = response.select { |record| record.send(k) == v }
        end
      end
      self.class.new(response)
    end

    def find_by(params)
      where(params).first
    end

    private

    attr_reader :records
  end
end
