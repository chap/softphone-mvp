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
  logger.debug "params=#{params}"
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
  to    = CGI::escapeHTML(params[:To])
  to    = "client:#{ENV['TWILIO_CLIENT_ID']}" if to == ENV['INBOUND_NUMBER']
  from  = params[:From]
  from  = ENV['OUTGOING_NUMBER']              if from.include?('client')

  response = Twilio::TwiML::Response.new do |r|
    r.Dial :callerId => from, :record => 'record-from-answer' do |d|
      to.include?('client') ? d.Client(to.gsub('client:','')) : d.Number(to)
    end
  end
  response.text
end
