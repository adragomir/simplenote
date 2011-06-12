require 'httparty'
require 'base64'
require 'crack'
require 'json'
require File.join(File.expand_path('..', __FILE__), 'simplenote_api2')

class SimpleNoteApi2
  include HTTParty
  attr_reader :token, :email
  base_uri 'https://simple-note.appspot.com/'

  def initialize(email, password)
    @email, @password = email, password
  end

  def token
    @token ||= login
  end

  def login
    encoded_body = Base64.encode64({:email => @email, :password => @password}.to_params)
    @email = email
    @token = self.class.post "/api/login", :body => encoded_body
    raise "Login failed" unless @token.response.is_a?(Net::HTTPOK)
    @token
  end

  def get_index(options={})
    self.class.get "/api2/index", :query => request_hash.merge(options), :format => :json
  end

  def get_note(key)
    out = (self.class.get "/api2/data/#{URI.encode(key)}", :query => request_hash, :format => :json)
    out.response.is_a?(Net::HTTPNotFound) ? nil : out
  end

  def delete_note(key, soft = true)
    if soft
      out = self.class.post "/api2/data/#{URI.encode(key)}", :query => request_hash.merge(:key => key), :body => {:deleted => 1}.to_json
      raise "Couldn't delete note" unless out.response.is_a?(Net::HTTPOK)
      out
    else
      raise 'hard deletes not yet implemented'
    end
  end

  def update_note(key, content_hash)
    self.class.post "/api2/data/#{URI.encode(key)}", :query => request_hash, :body =>  content_hash.to_json, :format => :json
  end
  
  def create_note(hash)
    self.class.post "/api2/data", :query => request_hash, :body => hash.to_json, :format => :json
  end


  private

  def request_hash
    { :auth => token, :email => email }
  end
end
