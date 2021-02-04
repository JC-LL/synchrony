require 'erb'
require_relative 'parser'
require_relative 'pretty_printer'
require_relative 'transformer'
require_relative 'code'

module Synchrony

  class Compiler

    attr_accessor :options
    attr_accessor :project_name

    def initialize options={}
      @options=options
    end

    def compile filename
      puts "=> compiling #{filename}"
      parse(filename)
    end

    def parse filename
      @ast=Parser.new.parse filename
    end

  end
end
