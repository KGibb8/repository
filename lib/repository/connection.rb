# frozen_string_literal: true

module Repository
  module Connection
    def self.connection(db_name)
      @connection ||= PG.connect(dbname: db_name)
    end
  end
end
