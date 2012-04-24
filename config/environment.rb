# Load the rails application

#require 'will_paginate'
require 'rubygems'
require 'composite_primary_keys'
require 'logger'
require 'json'

#require 'composite_primary_keys'
require File.expand_path('../application', __FILE__)



# Initialize the rails application
Dealmap::Application.initialize!
Rails.logger = Logger.new(STDOUT)

