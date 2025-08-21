module Synchrony

  class Scope < Hash
    def get str
      self[str]
    end

    def set str, obj
      self[str]=obj
    end
  end

  class Symtable
    attr_accessor :stack
    def initialize
      @stack=[]
      @stack << Scope.new
    end

    def current_scope
      @stack.last
    end

    def new_scope
      @stack << Scope.new
      current_scope
    end

    def close_scope
      @stack.pop
    end

    def get str
      @stack.reverse.each_with_index do |scope,level|
        if obj=scope[str]
          return obj
        end
      end
      nil
    end

    def set str, obj
      current_scope[str]=obj
    end
  end
end
