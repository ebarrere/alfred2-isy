#!/usr/bin/env ruby
# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__))
require 'open-uri'
require "bundle/bundler/isy"
require "alfred"
require "ruhue"
require "color"


Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  fb = alfred.feedback
  @debug = true
  @logger = Logger.new(File.expand_path("~/Library/Logs/Alfred-Workflow.log"))

  # puts "#{ARGV.class}"
  node_name, node_address, value = ARGV[0].split(':') # ARGV is a one-element array containing a :-delimited string
  # if value != "group"
  value = value.to_i
  # else
    # group = true
  # end
  node_address = URI::encode(node_address)
  url = value == 0 ? "/rest/nodes/#{node_address}/cmd/DON" : "/rest/nodes/#{node_address}/cmd/DOF"
  @logger.debug("url: #{url}") if @debug
  action = value == 0 ? "on" : "off"
  response = ISY.get(url)
  # puts response["RestResponse"]["succeeded"]
  unless response["RestResponse"]["succeeded"]
    response = ISY.get(/rest/)
    print "Call to #{url} failed!"
  else
    print "#{node_name} turned #{action}"
  end

  if node_name =~ /Hue lamps/ # set holiday color on hue lamps
    client = Ruhue::Client.new(Ruhue::discover, 'elliottbarrere')
    light1 = client.light(1)
    light2 = client.light(2)
    light3 = client.light(3)
    # light2.lselect
    # light2.hsl = Color::RGB::Orchid.to_hsl
    # light2.select
    # light2.hue=(39682)
    light1.hue=(0)
    light2.hue=(0)
  end
end