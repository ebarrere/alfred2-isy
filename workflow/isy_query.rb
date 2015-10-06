#!/usr/bin/env ruby
# encoding: utf-8

$: << File.expand_path(File.dirname(__FILE__))
require 'lib/isy'
require 'isy_config'

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require 'bundle/bundler/setup'
require 'alfred'

def faux_query(query)
  (query && query.length > 0) ? query : "..."
end

Alfred.with_friendly_error do |alfred|
  # set up logging
  log_file = File.new(File.expand_path("~/Library/Logs/Alfred-Workflow.log"),'a')
  logger = Logger.new(log_file)
  $stderr = log_file
  debug = false

  # configure alfred module
  alfred.with_rescue_feedback = true
  alfred.with_cached_feedback do
    # expire in 1 hour
    # use_cache_file :expire => 86400
    # use_cache_file :file => "/tmp/alfred2-isy_cache_file", :expire => 86400
  end

  # set program variables from Alfred's query string
  (query, value) = faux_query(ARGV.join(' ')).split(':')
  logger.debug("query: #{query}, value: #{value}") if debug

  # Test if cache exists and is valid
  if fb = alfred.feedback.get_cached_feedback # cached feedback is valid
    logger.debug("Cached feedback found ('#{alfred.feedback.backend_file}') and valid, using it") if debug
    # Make sure our cached items have the correct ARG value!
    # logger.debug("fb: #{fb.methods}")
    if value
      fb.items.each do |item|
        item.arg = item.arg.sub(/[^:]*$/,value)
      end
    end
    puts fb.to_alfred(query)
  else # cached feedback not valid or nonexistent
    logger.debug("Cached feedback not found or not valid, generating") if debug
    fb = alfred.feedback
    # fb.add_item({:title => 'waiting'})
    puts fb.to_alfred(query)
    isy = ISY.new($isy_config[:hostname], $isy_config[:username], $isy_config[:password])

    # handle nodes (single lights/non-scenes)
    isy.nodes.sort_by! { |hash| hash['name']}.each do |node|
      next if node["type"] =~ /3.7.74.0|0.18.0.0/ # hack to remove known "scenes" from node-list
      node_level = isy.node_level(node['address'])
      # add the item to Alfred Feedback
      fb.add_item({
        :title        => node['name'],
        :subtitle     => "address: #{node['address']}",
        :autocomplete => "#{node['name']}:",
        :arg          => "#{node['name']}:#{node['address']}:#{node_level}:#{value}",
        :valid        => "yes",
      })
    end

    # handle scenes, or "groups" in ISY-speak
    isy.groups.sort_by! { |hash| hash['name']}.reverse.each do |group|

      # first we calculate "on-ness" of the group
      # this is an average of the values of each group member
      # sum = 0
      # group["members"].each do |member|
      #   if group["name"] =~ / - / # skip e.g. "Stereo - Power" and "Remote - A"
      #     @avg_value = 255
      #     logger.debug("Average value of \"#{group['name']}\": #{@avg_value} (forced)") if debug
      #     next
      #   end

      #   # create an array of nodes in the group
      #   node_ids = Array.new
      #   member[1].each do |node_id|
      #     if node_id.is_a?(Hash)
      #       node_ids << node_id["__content__"]
      #     end
      #   end

      #   # loop through all known nodes, checking if it is a member of our group
      #   # if so, add its current value to our sum
      #   isy.nodes.each do |node|
      #     next unless node.has_key? 'address'
      #     next if node["name"] =~ / - / # skip e.g. "Stereo - Power" and "Remote - A"
      #     if node_ids.include? node['address']
      #       logger.debug("\"#{group['name']}\" total (#{sum}) += (#{node['property']['value']}) from \"#{node['name']}\"") if debug
      #       sum += node['property']['value'].to_i
      #     end
      #   end

      #   # calculate the average "on-ness"
      #   # logger.debug("node_ids: #{node_ids}")
      #   node_ids.length > 0 && @avg_value = sum/node_ids.length
      #   logger.debug("Average value of \"#{group['name']}\": #{@avg_value} (#{sum}/#{node_ids.length})") if debug
      # end

      # add the item to Alfred Feedback
      fb.add_item({
        :title        => group["name"],
        :subtitle     => "address: #{group["address"]}",
        # :subtitle     => st,
        :autocomplete => "#{group["name"]}:",
        :arg          => "#{group["name"]}:#{group["address"]}:0:#{value}",
        :valid        => "yes",
      })    
    end
    # puts fb.to_xml(query)
    fb.put_cached_feedback
    puts fb.to_alfred
  end

end