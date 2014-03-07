load(File.expand_path('../site.rb', __FILE__)) if File.exist?(File.expand_path('../site.rb', __FILE__))

ENV['RACK_ENV'] ||= 'development'
ENVIRONMENT = ENV['RACK_ENV'].to_sym

require 'rubygems'
require 'bundler'
require 'logger'
require 'json'
require 'nokogiri'
require 'pp'
require 'pebblebed'
require 'active_support/core_ext'
Bundler.require(:default, ENVIRONMENT)

Pebblebed.config do
  host 'homesdotcom.dev'
  service :checkpoint
  service :grove
end

Dir.glob(File.expand_path('../../lib/endeavor_image_integrator/**/*.rb', __FILE__)).each do |file_name|
  require file_name
end

unless defined?(LOGGER)
  $stdout.sync = true
  LOGGER = Logger.new($stdout)
  LOGGER.level = Logger::INFO
end