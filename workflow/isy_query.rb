#!/usr/bin/env ruby
# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__))
require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "bundle/bundler/isy"
require "alfred"


Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  fb = alfred.feedback


  query = ARGV[0]
  response = ISY.get("/rest/nodes/")
  unless response.class == HTTParty::Response
    raise Alfred::NoBundleIDError, "Got unexpected response class \"#{response.class}\" from ISY!  Check your URL."
  end
  nodes = response['nodes']['node']
  groups = response['nodes']['group']
  unless nodes.is_a? Array
    raise Alfred::NoBundleIDError, "Got wrong reply type from ISY!  Check your URL."
  end

  nodes.each do |node|
    unless node.has_key? 'name' and node["name"].is_a? String
      raise Alfred::NoBundleIDError, "ISY output is an unexpected type: #{node.class}"
    end
    # next if node["name"] =~ /Stereo|Remote|- Power/ # hack to remove known "scenes" from node-list
    next if node["type"] =~ /3.7.74.0|0.18.0.0/ # hack to remove known "scenes" from node-list
    fb.add_item({
      :uid          => "",
      :title        => node["name"],
      :subtitle     => "address: #{node["address"]}",
      :autocomplete => node["name"],
      :arg          => "#{node["name"]}:#{node["address"]}:#{node["property"]["value"]}",
      :valid        => "yes",
    })
  end
  groups.each do |group|
    fb.add_item({
      :uid          => "",
      :title        => group["name"],
      :subtitle     => "address: #{group["address"]}",
      :autocomplete => group["name"],
      :arg          => "#{group["name"]}:#{group["address"]}:group",
      :valid        => "yes",
    })    
  end
  puts fb.to_xml(ARGV)
end