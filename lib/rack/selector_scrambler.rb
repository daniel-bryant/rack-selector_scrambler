require "rack/selector_scrambler/hasher"
require "rack/selector_scrambler/version"

module Rack
  class SelectorScrambler
    HTML = "text/html"
    CSS = "text/css"
    JS = "application/javascript"

    def initialize(app, salt, *terms)
      @app = app
      @salt = salt
      @terms = terms
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      @env = env
      @status, @headers, @response = @app.call(env)
      [@status, @headers, self]
    end

    def each(&block)
      if filter?
        @response.each { |str| block.call(filter!(str)) }
      else
        @response.each(&block)
      end
    end

    private
      def filter?
        @terms.length > 0 && [HTML, CSS, JS].any? { |type| content_type? type }
      end

      def filter!(str)
        gsubber = if content_type?(HTML)
                    :gsub_html!
                  elsif content_type?(CSS)
                    :gsub_css!
                  elsif content_type?(JS)
                    :gsub_js!
                  end
        @terms.each { |term| send(gsubber, str, term) }
        str
      end

      def content_type?(type)
        @headers["Content-Type"].include? type
      end

      def gsub_html!(str, selector)
        str.gsub!(/(<.*?id=")#{selector}(".*?>)/, '\1' + hash(selector) + '\2')
        str.gsub!(/(<.*?class=".*?\b)#{selector}(\b.*?".*?>)/, '\1' + hash(selector) + '\2')
      end

      def gsub_css!(str, selector)
        str.gsub!(/([#|\.])#{selector}([\s|{])/, '\1' + hash(selector) + '\2')
      end

      def gsub_js!(str, selector)
        str.gsub!(/('|")([#|.]?)(#{selector})\1/, '\1\2' + hash(selector) + '\1')
      end

      def hash(term)
        hasher.djb3(term)
      end

      def hasher
        @hasher ||= Hasher.new(Rack::Request.new(@env).ip, @salt)
      end
  end
end
