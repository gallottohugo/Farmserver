require 'rubygems'
require 'rest_client'
require 'json'

desc "Export heats data from tambero JSON"
task :export_confim_heats => :environment do
  Heat.export_heats
end