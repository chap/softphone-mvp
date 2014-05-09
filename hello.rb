require 'sinatra'
require 'twilio-ruby'
require 'json'
require 'newrelic_rpm'
require 'coffee-script'

require './env' if File.exists?('env.rb')

get '/widget.js' do
  response.headers['Access-Control-Allow-Origin'] = '*'
  if ((request.secure? || ENV['RACK_ENV'] == 'development') && params[:auth] == ENV['AUTH_PARAM'])
    capability = Twilio::Util::Capability.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
    capability.allow_client_outgoing ENV['TWILIO_OUTGOING_APP_ID']
    capability.allow_client_incoming ENV['TWILIO_CLIENT_ID']
    @token = capability.generate

    coffee(erb 'widget.js.coffee'.to_sym)
  else
    { :error => 'bad request' }.to_json
  end
end

post '/widget.html' do
  response.headers['Access-Control-Allow-Origin'] = '*'
  if ((request.secure? || ENV['RACK_ENV'] == 'development') && params[:auth] == ENV['AUTH_PARAM'])
    capability = Twilio::Util::Capability.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
    capability.allow_client_outgoing params[:outgoing_app_id]
    capability.allow_client_incoming params[:client_id]
    @token = capability.generate

    erb('widget.html'.to_sym, :layout => false)
  else
    "<div>Error: bad request (must be SSL and include auth param)</div>"
  end
end

post '/voice' do
  number = params[:PhoneNumber]
  response = Twilio::TwiML::Response.new do |r|
    r.Dial :callerId => ENV['OUTGOING_NUMBER'] do |d|
      # Test to see if the PhoneNumber is a number, or a Client ID.
      if /^[\d\+\-\(\) ]+$/.match(number)
        # outbound call
        d.Number(CGI::escapeHTML number)
      else
        # inbound call
        d.Client ENV['TWILIO_CLIENT_ID']
      end
    end
  end
  response.text
end
