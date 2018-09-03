require "spec_helper"

RSpec.describe Repository::Base do
  Person = Class.new(Repository::Base)
  let(:params) { { first_name: "Ellie", middle_name: "the", last_name: "Elephant" } }
  let(:person) { Person.new(params) }

  describe "#initialize" do
    it "requires a hash" do
      expect { Person.new("Ellie the Elephant") }
        .to raise_error(ArgumentError)
        .with_message("initialize with a hash")

      expect(person).to be_a_kind_of Person
    end
  end

  describe "#attributes" do
    it "returns a hash" do
      expect(person.attributes).to eq(first_name: "Ellie", middle_name: "the", last_name: "Elephant")
    end
  end

  describe "#==" do
    context "class" do
      Monkey = Class.new(Repository::Base)
      let (:monkey) { Monkey.new(first_name: "Ooky", middle_name: "the", last_name: "Skreecher") }

      it "is falsey if of a different class" do
        expect(person == monkey).to be_falsey
      end
    end

    context "attributes" do
      let(:other) { person.dup }

      it "is falsey if attributes don't match" do
        other.first_name = "Smellie"
        expect(other == person).to be_falsey
      end

      it "is falsey if duplicate has extra attributes" do
        other.class.__send__(:attr_accessor, :title)
        other.title = "Baroness"
        expect(other == person).to be_falsey
      end

      it "is truthy if attributes match" do
        expect(other == person).to be_truthy
      end
    end
  end
end
