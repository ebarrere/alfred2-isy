#!/usr/bin/env ruby
# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__))
require 'lib/isy'
require 'alfred'
require 'open-uri'
require 'ruhue'
require 'color'


Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  fb = alfred.feedback
  log_file = File.new(File.expand_path("~/Library/Logs/Alfred-Workflow.log"),'a')
  logger = Logger.new(log_file)
  $stderr = log_file
  debug = true

  # logger.debug("#{ARGV}") if debug
  node_name, node_address, node_level, value = ARGV[0].split(':') # ARGV is a one-element array containing a :-delimited string
  # if value != "group"
  # value = value.to_i
  logger.debug("node_name: \"#{node_name}\", node_address: \"#{node_address}\", node_level: \"#{node_level}\", value: \"#{value}\"") if debug
  # else
    # group = true
  # end

  isy = ISY.new('https://t.0o0.bz','admin','password')

  # TODO: GROUPS SHOULD ALWAYS HIT DON
  case value
  when 'on'
    logger.debug("Turning #{node_address} on.") if debug
    logger.debug(isy.node_on(node_address))
  when /^(off|0+)$/
    logger.debug("Turning #{node_address} off.") if debug
    logger.debug(isy.node_off(node_address))
  when /^[0-9]+$/
    logger.debug("Setting #{node_address} to #{value}.") if debug
    logger.debug(isy.set_node_level(node_address,value))
  else
    logger.debug("#{node_address} toggled") if debug
    logger.debug(isy.node_on?(node_address) ? isy.node_off(node_address) : isy.node_on(node_address))
  end
  # node_address = URI::encode(node_address)
  # url = value == 0 ? "/rest/nodes/#{node_address}/cmd/DOF" : "/rest/nodes/#{node_address}/cmd/DON/#{value}"
  # # url = value == 0 ? "/rest/nodes/#{node_address}/cmd/DON/#{value}" : "/rest/nodes/#{node_address}/cmd/DOF"
  # logger.debug("url: #{url}") if debug
  # action = value == 0 ? "on" : "off"
  # response = ISY.get(url)
  # # puts response["RestResponse"]["succeeded"]
  # unless response["RestResponse"]["succeeded"]
  #   response = ISY.get(/rest/)
  #   print "Call to #{url} failed!"
  # else
  #   print "#{node_name} turned #{action}"
  # end

  # if node_name =~ /Hue lamps/ # set random color on hue lamps
  #   sleep(1)
  #   client = Ruhue::Client.new(Ruhue::discover, 'elliottbarrere')
  #   light1 = client.light(1)
  #   light2 = client.light(2)
  #   light3 = client.light(3)
  #   # light2.lselect
  #   # light2.hsl = Color::RGB::Orchid.to_hsl
  #   # light2.select
  #   # light2.hue=(39682)
  #   light1.hue=(rand(2**16-1))
  #   light2.hue=(rand(2**16-1))
  #   light3.on
  #   light3.hue=(rand(2**16-1))
  # end
end