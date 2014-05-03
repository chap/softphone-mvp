require 'sinatra'
require 'twilio-ruby'
require 'json'
require 'newrelic_rpm'

get '/token' do
  content_type :json
  response.headers['Access-Control-Allow-Origin'] = '*'

  if request.secure? && params[:auth] == ENV['AUTH_PARAM']
    capability = Twilio::Util::Capability.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
    capability.allow_client_outgoing ENV['TWILIO_OUTGOING_APP_ID']
    capability.allow_client_incoming ENV['TWILIO_CLIENT_ID']
    token = capability.generate

    { :token => token }.to_json
  else
    { :error => 'bad request' }.to_json
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
