require "spec_helper"

describe Rack::SelectorScrambler do
  class MockApp
    def initialize(response, content_type)
      @response = response
      @content_type = content_type
      @content_length = @response.reduce(0) { |total, str| total += str.length }
    end

    def call(env)
      [200, {"Content-Type" => @content_type, "Content-Length" => @content_length}, @response]
    end
  end

  let(:salt) { "foobar" }
  let(:terms) { ["bannerad", "bannerAd", "foo"] }
  subject { described_class.new(app, salt, *terms) }
  let(:res) { Rack::MockRequest.new(subject).get("") }

  it "has a version number" do
    expect(Rack::SelectorScrambler::VERSION).not_to be nil
  end

  describe "an instance" do
    let(:app) { MockApp.new([@body], content_type) }

    context "when Content-Type is text/html" do
      let(:content_type) { 'text/html' }

      it "replaces matching ids" do
        @body = '<div id="foo"></div>'
        expect(res.body).to match(/<div id="(?!foo").+"><\/div>/)
      end

      it "replaces matching classes" do
        @body = '<div class="foo"></div>'
        expect(res.body).to match(/<div class="(?!foo").+"><\/div>/)
      end

      it "does not replace unmatched values" do
        @body = '<div class="foo someclass"></div>'
        expect(res.body).to match(/<div class="(?!foo ).+ someclass"><\/div>/)
      end

      it "does not replace inexact matches" do
        @body = '<div class="xfoox"></div>'
        expect(res.body).to eq('<div class="xfoox"></div>')
      end

      it "does not replace non id or class values" do
        @body = '<div src="foo"></div>'
        expect(res.body).to eq('<div src="foo"></div>')
      end

      it "does not replace attribute names" do
        @body = '<div foo="value"></div>'
        expect(res.body).to eq('<div foo="value"></div>')
      end
    end

    context "when Content-Type is text/css" do
      let(:content_type) { 'text/css' }

      it "replaces ids" do
        @body = '#foo { some: value }'
        expect(res.body).to match(/#(?!foo ).+ { some: value }/)
      end

      it "replaces classes" do
        @body = '.foo { some: value }'
        expect(res.body).to match(/\.(?!foo ).+ { some: value }/)
      end

      it "replaces multiple instances" do
        @body = '#foo .foo { some: value }'
        expect(res.body).to match(/#(?!foo ).+ \.(?!foo ).+ { some: value }/)
      end

      it "only replaces exact matches" do
        @body = '#foo-foo { some: value }'
        expect(res.body).to eq('#foo-foo { some: value }')
      end

      it "does not replace non ids or classes" do
        @body = 'div { foo: foo }'
        expect(res.body).to eq('div { foo: foo }')
      end
    end

    context "when Content-Type is application/javascript" do
      let(:content_type) { 'application/javascript' }

      it "replaces a term alone in the string" do
        @body = 'var selector = "foo";'
        expect(res.body).to match(/^var selector = "(?!foo").+";$/)
      end

      it "does not replace terms used outside of a string" do
        @body = 'var foo = "id"'
        expect(res.body).to eq('var foo = "id"')
      end

      it "does not replace terms that aren't alone inside of a string" do
        @body = 'var id = "foo is cool"'
        expect(res.body).to eq('var id = "foo is cool"')
      end

      it "allows a hash sign for ids" do
        @body = 'var selector = "#foo"'
        expect(res.body).to match(/^var selector = "#(?!foo").+"$/)
      end

      it "allows a dot for classes" do
        @body = 'var selector = ".foo"'
        expect(res.body).to match(/^var selector = "\.(?!foo").+"$/)
      end

      it "accounts for escaped quotes" do
        @body = 'var quote = "\""; var selector = "foo";'
        expect(res.body).to match(/^var quote = "\\""; var selector = "(?!foo").+";$/)
      end
    end

    context "when the response is changed" do
      let(:content_type) { 'text/html' }

      it "contains the correct Content-Length header, accounting for the hash salt" do
        @body = '<html><body><h1 id="bannerad">Ad</h1></body></html>'
        expected_length = @body.length + salt.length
        expect(res.headers["Content-Length"]).to eq(expected_length.to_s)
      end
    end
  end

  describe "response from fixtures" do
    let(:body) do
      %w[part_one part_two].map do |part|
        File.open("#{File.dirname(__FILE__)}/../fixtures/#{part}.html", "rb") { |f| f.read }
      end
    end
    let(:content_type) { "text/html" }
    let(:app) { MockApp.new(body, content_type) }

    RSpec.shared_examples "a NON filtered page" do
      it "contains all original ids" do
        expect(res.body).to include('id="bannerAd"')
        expect(res.body).to include('id="bannerad"')
      end
      it "contains all original class names" do
        expect(res.body).to include('class="testclass1 bannerAd"')
        expect(res.body).to include('class="testclass2 bannerad"')
      end
      it "does not filter anything that is not an id or class" do
        expect(res.body).to include('This should not be replaced: <strong>bannerAd</strong>')
        expect(res.body).to include('This should not be replaced: <strong>bannerad</strong>')
      end
    end

    RSpec.shared_examples "a filtered page" do
      it "contains filtered ids" do
        expect(res.body).not_to include('id="bannerAd"')
        expect(res.body).not_to include('id="bannerad"')
      end
      it "contains filtered class names" do
        expect(res.body).not_to include('class="testclass1 bannerAd"')
        expect(res.body).not_to include('class="testclass2 bannerad"')
      end
      it "does not filter anything that is not an id or class" do
        expect(res.body).to include('This should not be replaced: <strong>bannerAd</strong>')
        expect(res.body).to include('This should not be replaced: <strong>bannerad</strong>')
      end
    end

    context "when Content-Type is a filtered type and terms are given" do
      it_behaves_like "a filtered page"
    end

    context "when Content-Type is not a filtered type" do
      let(:content_type) { "text/foo" }
      it_behaves_like "a NON filtered page"
    end

    context "when no terms are given" do
      let(:terms) { [] }
      it_behaves_like "a NON filtered page"
    end
  end
end
