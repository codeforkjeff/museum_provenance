require "museum_provenance/version"

# Load dependent files
require 'date'
require 'date_time_precision'
require 'date_time_precision/format/iso8601'
require 'date_time_precision/format/string'

Dir["#{File.dirname(__FILE__)}/museum_provenance/**/*.rb"].each { |f| require(f) }

# MuseumProvenance is a library designed to extend
# @todo Write this, dodo
module MuseumProvenance
end