#!/usr/bin/env ruby
# encoding: utf-8

require 'httparty'

class ISY
  include HTTParty
  base_uri 'http://192.168.50.21'
  format :xml
  basic_auth 'admin', 'password'
  # self.verify_mode = OpenSSL::SSL::VERIFY_NONE
  # debug_output  
end