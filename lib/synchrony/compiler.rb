module Synchrony
  class Compiler
    attr_accessor :options
    def compile filename
      @ast=Parser.new.parse(filename)
      Visitor.new.visit(@ast)
      PrettyPrinter.new.print(@ast)
    end
  end
end
