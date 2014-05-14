require 'sinatra'
require 'twilio-ruby'
require 'json'
require 'newrelic_rpm'
require 'coffee-script'

require './env' if File.exists?('env.rb')

get '/widget.js' do
  response.headers['Access-Control-Allow-Origin'] = '*'
  coffee(erb 'widget.js.coffee'.to_sym)
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
  inbound   = (params[:Direction] == 'inbound')
  to        = CGI::escapeHTML(params[:To] || ENV['TWILIO_CLIENT_ID'])
  to_number = (/^[\d\+\-\(\) ]+$/.match(to))
  from      = (inbound ? params[:From] : ENV['OUTGOING_NUMBER'])

  response = Twilio::TwiML::Response.new do |r|
    r.Dial :callerId => from do |d|
      to_number ? d.Number : d.Client
    end
  end
  response.text
end
