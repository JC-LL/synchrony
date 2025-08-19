module Synchrony

  class AstNode
    def accept(visitor, arg=nil)
       name = self.class.name.split(/::/).last
       visitor.send("visit#{name}".to_sym, self ,arg) # Metaprograming !
    end

    def str
      ppr=PrettyPrinter.new
      self.accept(ppr)
    end
  end

  class SingleTokenNode < AstNode
    attr_accessor :tok
    def initialize tok
      @tok=tok
    end
  end

  class Root < AstNode
    attr_accessor :elements
    def initialize
      @elements=[]
    end

    def <<(e)
      @elements << e
    end
  end
  #========================
  class Require < AstNode
    attr_accessor :circuit_name
    def initialize circuit_name
      @circuit_name=circuit_name
    end
  end
  #========================
  class Circuit < AstNode
    attr_accessor :name,:inputs,:outputs,:wires,:instances,:body
    def initialize name=nil,inputs=[],outputs=[],wires=[],instances=[],body=nil
      @name,@inputs,@outputs,@body=name,inputs,outputs,instances,body
    end
  end
  #========================
  class Sig < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class Input < Sig
  end

  class Output < Sig
  end

  class Wire < Sig
  end
  #============================
  class Type < AstNode
    attr_accessor :nb_bits
    def initialize nb_bits=1
      @nb_bits=nb_bits
    end
  end

  class Bit < Type
  end

  class Bits < Type
  end

  class Int < Type
  end

  class Uint < Type
  end
  #============================
  class Instance < AstNode
    attr_accessor :name,:model
    def initialize name=nil,model=nil
      @name,@model=name,model
    end
  end

  #========================
  class Body < AstNode
    attr_accessor :stmts
    def initialize stmts=[]
      @stmts=stmts
    end

    def <<(e)
      @stmts << e
    end
  end

  class Map < AstNode
    attr_accessor :call
    def initialize call=nil
      @call=call
    end
  end

  class Assign < AstNode
    attr_accessor :lhs,:rhs
  end

  class CombAssign < Assign
  end

  class SeqAssign < Assign
  end

  #========================
  class Ident < SingleTokenNode
  end

  class IntLit < SingleTokenNode
  end

  class StrLit < SingleTokenNode
  end

  class CondExpr < AstNode
    attr_accessor :cond,:lhs,:rhs
    def initialize cond=nil,lhs=nil,rhs=nil
      @cond,@lhs,@rhs=cond,lhs,rhs
    end
  end

  class Binary < AstNode
    attr_accessor :lhs,:op,:rhs
    def initialize lhs,op,rhs
      @lhs,@op,@rhs=lhs,op,rhs
    end
  end

  class Unary < AstNode
    attr_accessor :expr

    def initialize op,expr
      @op,@expr=op,expr
    end
  end

  class DotExpr < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs,rhs
      @lhs,@rhs=lhs,rhs
    end
  end

  class Parenth < AstNode
    attr_accessor :expr
    def initialize expr
      @expr=expr
    end
  end

  class Call < AstNode
    attr_accessor :name,:args
    def initialize name,args=[]
      @name,@args=name,args
    end
  end

  class BitField < AstNode
    attr_accessor :expr,:range
    def initialize expr=nil,range=nil
      @expr,@range=expr,range
    end
  end

  class Range < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Concat < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end


end
