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
      self.errors.add(:from, "cannot be equal to :to" )
    end
  end

  def initialize(api_key='')
    @to = 'Kevin Bacon'
    @from = 'Kevin Bacon'
    @api_key = api_key  
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
      raise OracleOfBacon::NetworkError
    end
    # your code here: create the OracleOfBacon::Response object
    OracleOfBacon::Response.new(xml)
  end

  def make_uri_from_arguments
    # your code here: set the @uri attribute to properly-escaped URI
    #   constructed from the @from, @to, @api_key arguments
    from, to, key_api = CGI.escape(@from), CGI.escape(@to), CGI.escape(@api_key)
    @uri = 'http://oracleofbacon.org/p=' << key_api << '&a=' << from << '&b=' << to
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
      if ! @doc.xpath('/error').empty?
        parse_error_response
      # your code here: 'elsif' clauses to handle other responses
      # for responses not matching the 3 basic types, the Response
      # object should have type 'unknown' and data 'unknown response'   
      elsif ! @doc.xpath('/spellcheck').empty?
        parse_spellcheck_response
      elsif ! @doc.xpath('/other').empty?
        parse_unknown_response
      else 
        parse_graph_response
      end
    end
    def parse_spellcheck_response
      @type = :spellcheck
      @data = []
      @doc.xpath('//match').each { |item| @data.push(item.content) }
    end
    def parse_unknown_response
      @type = :unknown
      @data = 'unknown response type'
    end
    def parse_graph_response
      @type = :graph
      @data_actor, @data_movie = [], []
      @doc.xpath('//actor').each { |item| @data_actor.push(item.content) }
      @doc.xpath('//movie').each { |item| @data_movie.push(item.content) }
      @data = @data_actor.zip(@data_movie).flatten.compact
    end
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end
  end
end

