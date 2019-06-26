require 'rubygems'
require 'rest_client'
require 'json'

desc "Import animal and heat data from tambero JSON"
task :import_from_tambero => :environment do
  Animal.add_from_tambero
  Animal.deactivate_from_tambero
  Animal.update_from_tambero
  Heat.export_heats
end
