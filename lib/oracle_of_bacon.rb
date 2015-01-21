require 'debugger'              # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    if @from == @to
      errors.add(:from_to, "From cannot be the same as To")
    end
  end

  def initialize(api_key='')
    @api_key = api_key
    @from = "Kevin Bacon"
    @to = "Kevin Bacon"
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      # your code here
    end
    # your code here: create the OracleOfBacon::Response object
  end

  def make_uri_from_arguments
    escaped_to = CGI::escape @to
    escaped_from = CGI::escape @from
    @uri = "http://oracleofbacon.org/cgi-bin/xml?p=#{ @api_key }&a=#{ escaped_from }&b=#{ escaped_to }"

    # Why this doesn't work?
    # @uri =  CGI::escape "http://oracleofbacon.org/cgi-bin/xml?p=#{ @api_key }&a=#{ @from }&b=#{ @to }"
  end
      
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      if @doc.xpath('/error').present?
        parse_error_response
      elsif @doc.xpath('/link').present?
        parse_graph_response
      elsif @doc.xpath('/spellcheck').present?
        parse_spellcheck_response
      else
        @type = :unknown
        @data = "Unknown Response"
      # your code here: 'elsif' clauses to handle other responses
      # for responses not matching the 3 basic types, the Response
      # object should have type 'unknown' and data 'unknown response'         
      end
    end

    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end

    def parse_graph_response
      @type = :graph
      @data = @doc.xpath('//link').children.select{ |a| a.elem? }.map(&:text)
    end

    def parse_spellcheck_response
      @type = :spellcheck
      @data = @doc.xpath('//spellcheck/match').map(&:text)
    end
  end
end

