module Synchrony
  class Compiler
    include InfoDisplay

    attr_accessor :options

    def compile filename

      parse filename
      visit
      pretty_print
      name_resolution
      if @nb_errors==0
        type_checking
      end
    end

    def parse filename
      info 0, "parsing '#{filename}'"
      @ast=Parser.new.parse(filename)
    end

    def visit
      info 0, "visiting ast"
      Visitor.new.visit(@ast)
    end

    def pretty_print
      info 0, "pretty print"
      PrettyPrinter.new.print(@ast)
    end

    def name_resolution
      info 0, "name resolution"
      resolver=Resolver.new
      resolver.resolve(@ast)
      @nb_errors=resolver.nb_errors
    end

    def type_checking
      info 0, "type checking"
      TypeChecker.new.check(@ast)
    end

  end
end
