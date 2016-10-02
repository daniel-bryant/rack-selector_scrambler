require "spec_helper"

describe Rack::SelectorScrambler::Hasher do
  describe "#djb2" do
    let(:result) { 8246957354742647644 }

    it "returns the result of performing the djb2 algorithm on the arg" do
      expect(described_class.new.djb2("teststring")).to eq(result)
    end

    it "prepends the salt(s) before performing djb2" do
      expect(described_class.new("te", "st").djb2("string")).to eq(result)
    end
  end

  describe "#djb3" do
    let(:result) { "FLTdBvhVmf" }

    it "returns the result of performing the djb3 algorithm on the arg" do
      expect(described_class.new.djb3("teststring")).to eq(result)
    end

    it "prepends the salt(s) before performing djb3" do
      expect(described_class.new("te", "st").djb3("string")).to eq(result)
    end
  end
end
