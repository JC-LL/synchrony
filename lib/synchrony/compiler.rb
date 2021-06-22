require_relative 'parser'
require_relative 'visitor'
require_relative 'pretty_printer'
require_relative 'elaborator'
require_relative 'nary_transformer'
require_relative 'boolean_simplifier'
require_relative 'transformer'
require_relative 'code'
require_relative 'info_printer'

module Synchrony

  class Compiler

    attr_accessor :options
    attr_accessor :project_name
    attr_accessor :ast
    include InfoPrinter

    def initialize options={}
      @options=options
    end

    def compile filename
      info 0,"compiling #{filename}"
      $basename=File.basename(filename,'.syc')
      @ast=parse(filename)
      #visit(ast)
      #pretty_print(ast)
      #new_ast=dummy_transform(ast) # to check transformer is ok
      #pretty_print(new_ast,"tr")
      simplify(@ast) if @options[:simplify]
      elaborate(@ast)
    end

    def parse filename
      @ast=Parser.new.parse filename
    end

    def visit ast
      info 1,"simple visit"
      Visitor.new.visit(ast)
    end

    def pretty_print ast,pass_name=nil
      info 1,"pretty printing "
      PrettyPrinter.new.print(ast,pass_name)
    end

    def simplify ast
      info 1,"boolean simplifications"
      nary_ast=NaryTransformer.new.transform(ast)
      #pretty_print nary_ast
      @ast=BooleanSimplifier.new.simplify(nary_ast)
      pretty_print @ast,"simplified"
      abort
    end

    def dummy_transform ast
      info 1,"dummy transform "
      Transformer.new.transform(ast)
    end

    def elaborate ast
      info 1,"elaboration"
      Elaborator.new.elaborate(ast)
    end
  end
end
