#!/usr/bin/env ruby
# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__))
require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "isy"
require "alfred"

  

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  fb = alfred.feedback

  # set up logging
  @logger = Logger.new(File.expand_path("~/Library/Logs/Alfred-Workflow.log"))
  @debug = false

  # set variables and make call to ISY
  query = ARGV[0]
  response = ISY.get("/rest/nodes/")
  unless response.class == HTTParty::Response
    raise Alfred::NoBundleIDError, "Got unexpected response class \"#{response.class}\" from ISY!  Check your URL."
  end
  nodes = response['nodes']['node'].sort_by! { |hash| hash['name']}
  groups = response['nodes']['group'].sort_by! { |hash| hash['name']}
  unless nodes.is_a? Array
    raise Alfred::NoBundleIDError, "Got wrong reply type from ISY!  Check your URL."
  end
  unless nodes[1].has_key? 'name' and nodes[1]["name"].is_a? String
    raise Alfred::NoBundleIDError, "ISY output is an unexpected type: #{nodes[1].class}"
  end

  # handle nodes (single lights/non-scenes)
  nodes.each do |node|
    next if node["type"] =~ /3.7.74.0|0.18.0.0/ # hack to remove known "scenes" from node-list
    # add the item to Alfred Feedback
    fb.add_item({
      :uid          => "",
      :title        => node["name"],
      :subtitle     => "address: #{node["address"]}",
      :autocomplete => node["name"],
      :arg          => "#{node["name"]}:#{node["address"]}:#{node["property"]["value"]}",
      :valid        => "yes",
    })
  end

  # handle scenes, or "groups" in ISY-speak
  groups.each do |group|
    # first we calculate "on-ness" of the group
    # this is an average of the values of each group member
    sum = 0
    group["members"].each do |member|
      if group["name"] =~ / - / # skip e.g. "Stereo - Power" and "Remote - A"
        @avg_value = 0
        @logger.debug("Average value of \"#{group['name']}\": #{@avg_value} (forced)") if @debug
        next
      end

      # create an array of nodes in the group
      node_ids = Array.new
      member[1].each do |node_id|
        if node_id.is_a?(Hash)
          node_ids << node_id["__content__"]
        end
      end

      # loop through all known nodes, checking if it is a member of our group
      # if so, add its current value to our sum
      nodes.each do |node|
        next unless node.has_key? 'address'
        next if node["name"] =~ / - / # skip e.g. "Stereo - Power" and "Remote - A"
        if node_ids.include? node['address']
          @logger.debug("\"#{group['name']}\" total (#{sum}) += (#{node['property']['value']}) from \"#{node['name']}\"") if @debug
          sum += node['property']['value'].to_i
        end
      end

      # calculate the average "on-ness"
      @avg_value = sum/node_ids.length
      @logger.debug("Average value of \"#{group['name']}\": #{@avg_value} (#{sum}/#{node_ids.length})") if @debug
    end

    # add the item to Alfred Feedback
    fb.add_item({
      :uid          => "",
      :title        => group["name"],
      :subtitle     => "address: #{group["address"]}",
      # :subtitle     => st,
      :autocomplete => group["name"],
      :arg          => "#{group["name"]}:#{group["address"]}:#{@avg_value}",
      :valid        => "yes",
    })    
  end
  puts fb.to_xml(ARGV)
end
