require "spec_helper"
require "securerandom"

RSpec.describe Repository::Collection do
  Person = Class.new(Repository::Base)
  let(:records) do
    Repository::Collection.new(
      (0...20).to_a.map do |num|
        Person.new(
          id: SecureRandom.uuid,
          height: num,
          size: "Micro",
          name: "Bobby the #{num}"
        )
      end
    )
  end

  describe "#all" do
    it "returns a Collection object" do
      expect(records.all).to be_a_kind_of Repository::Collection
    end
  end

  describe "#each" do
    it "implements Enumerable methods" do
      expect(records).to respond_to(:each)
    end
  end

  describe "#where" do
    context "with matching attributes" do
      it "returns a Collection object" do
        query = records.where(size: "Micro")
        expect(query).to be_a_kind_of Repository::Collection
        expect(query.count).to eq 20
      end

      it "allows for chained queries" do
        query = records.where(size: "Micro")
        expect(query.count).to eq 20
        query = query.where(name: "Bobby the 15")
        expect(query.count).to eq 1
      end
    end

    context "without matching attributes" do
      it "returns an empty Collection object" do
        query = records.where(height: 54)
        expect(query).to be_a_kind_of Repository::Collection
        expect(query.count).to eq 0
      end
    end
  end

  describe "#find_by" do
    it "takes the first item from a collection" do
      person = records.find_by(size: "Micro")
      expect(person).to be_a_kind_of Person
      expect(person == records.first)
    end

    it "returns nil if nothing found" do
      person = records.find_by(size: "Giant")
      expect(person).to be_nil
    end
  end
end
