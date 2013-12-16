#!/usr/bin/env ruby
# encoding: utf-8

<<<<<<< HEAD
=======
$: << File.expand_path(File.dirname(__FILE__))
>>>>>>> 5b838ce... initial commit
require 'rubygems' unless defined? Gem
require "bundle/bundler/setup"
require "alfred"


def something_goes_wrong
  true
end

Alfred.with_friendly_error do |alfred|
  alfred.with_rescue_feedback = true

  fb = alfred.feedback

  if something_goes_wrong
    raise Alfred::NoBundleIDError, "Wrong Bundle ID Test!"
  end
end



