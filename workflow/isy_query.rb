#!/usr/bin/env ruby
# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__))
require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require 'open-uri'
require "bundle/bundler/setup"
require "isy"
require "alfred"

def faux_query(query)
  (query && query.length > 0) ? query : "..."
end

def check_node(type,query,address)
  q_string = %Q!#{type}["name"]!
  node_address = address
  if @new_value
    value = @new_value
  elsif query =~ /#{q_string}/
    node_address = URI::encode(group["address"])
    @new_value = ISY.get("/rest/nodes/#{node_address}")["nodeInfo"]["properties"]["property"][0]["value"]
    cur_value = ISY.get("/rest/nodes/#{node_address}")["nodeInfo"]["properties"]["property"][2]["value"]
    if @new_value == cur_value
      value = 0
    else
      value = @new_value
    end
  end
end

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true
  fb = alfred.feedback

  # set up logging
  @logger = Logger.new(File.expand_path("~/Library/Logs/Alfred-Workflow.log"))
  @debug = false

  # set variables and make call to ISY
  query = faux_query(ARGV.join(' '))
  query = query.split(':').first
  @new_value = faux_query(ARGV.join(' '))
  @new_value = @new_value.split(':')[1]
  @new_value = @new_value.to_i if @new_value

  response = ISY.get("/rest/nodes/")
  unless response.class == HTTParty::Response
    raise Alfred::NoBundleIDError, "Got unexpected response class \"#{response.class}\" from ISY!  Check your URL."
  end
  nodes = response['nodes']['node'].sort_by! { |hash| hash['name']}
  groups = response['nodes']['group'].sort_by! { |hash| hash['name']}.reverse
  unless nodes.is_a? Array
    raise Alfred::NoBundleIDError, "Got wrong reply type from ISY!  Check your URL."
  end
  unless nodes[1].has_key? 'name' and nodes[1]["name"].is_a? String
    raise Alfred::NoBundleIDError, "ISY output is an unexpected type: #{nodes[1].class}"
  end

  # handle nodes (single lights/non-scenes)
  nodes.each do |node|
    next if node["type"] =~ /3.7.74.0|0.18.0.0/ # hack to remove known "scenes" from node-list
    value = check_node(node,query,node["address"])
    # if @new_value
    #   value = @new_value
    # elsif query =~ /#{node["name"]}/
    #   node_address = URI::encode(node["address"])
    #   @new_value = ISY.get("/rest/nodes/#{node_address}")["nodeInfo"]["properties"]["property"][0]["value"]
    #   cur_value = ISY.get("/rest/nodes/#{node_address}")["nodeInfo"]["properties"]["property"][2]["value"]
    #   if @new_value == cur_value
    #     value = 0
    #   else
    #     value = @new_value
    #   end
    # end
    # add the item to Alfred Feedback
    fb.add_item({
      :title        => node["name"],
      :subtitle     => "address: #{node["address"]}",
      :autocomplete => "#{node["name"]}:",
      :arg          => "#{node["name"]}:#{node["address"]}:#{value}:#{@new_value}",
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
        @avg_value = 255
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
      # @logger.debug("node_ids: #{node_ids}")
      node_ids.length > 0 && @avg_value = sum/node_ids.length
      @logger.debug("Average value of \"#{group['name']}\": #{@avg_value} (#{sum}/#{node_ids.length})") if @debug
    end

    # add the item to Alfred Feedback
    fb.add_item({
      :title        => group["name"],
      :subtitle     => "address: #{group["address"]}",
      # :subtitle     => st,
      :autocomplete => "#{group["name"]}:",
      :arg          => "#{group["name"]}:#{group["address"]}:#{@avg_value}:#{@new_value}",
      :valid        => "yes",
    })    
  end
  puts fb.to_xml(query)
end