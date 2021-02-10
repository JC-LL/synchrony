require 'erb'
require_relative 'parser'
require_relative 'visitor'
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
      ast=parse(filename)
      visit(ast)
      pretty_print(ast)
    end

    def parse filename
      @ast=Parser.new.parse filename
    end

    def visit ast
      puts "=> simple visit"
      Visitor.new.visit(ast)
    end

    def pretty_print ast
      puts "=> pretty printing "
      PrettyPrinter.new.print(ast)
    end

  end
end
