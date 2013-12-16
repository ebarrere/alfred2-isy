#!/usr/bin/env ruby
# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__))
require 'open-uri'
require "bundle/bundler/isy"
require "alfred"


Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  fb = alfred.feedback

  # puts "#{ARGV.class}"
  node_name, node_address, value = ARGV[0].split(':') # ARGV is a one-element array containing a :-delimited string
  if value != "group"
    value = value.to_i
  else
    group = true
  end
  node_address = URI::encode(node_address)
  if group
    members = ISY.get("/rest/nodes/#{node_address}?members=true")['nodeInfo']['group']['members']
    members.each do |member|
      
    url = "/rest/nodes/#{node_address}/cmd/DON"
    action = value == 0 ? "on" : "off"
  else
    url = value == 0 ? "/rest/nodes/#{node_address}/cmd/DON" : "/rest/nodes/#{node_address}/cmd/DOF"
    action = value == 0 ? "on" : "off"
  end
  puts url
  response = ISY.get(url)
  # puts response["RestResponse"]["succeeded"]
  unless response["RestResponse"]["succeeded"]
    response = ISY.get(/rest/)
    print "Call to #{url} failed!"
  else
    print "#{node_name} turned #{action}"
  end
end