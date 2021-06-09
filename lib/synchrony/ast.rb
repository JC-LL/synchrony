# your project process may use rkgen for class generation :
# require_relative "ast_synchrony_rkgen"

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

  class Root < AstNode
    attr_accessor :elements
    def initialize elements=[]
      @elements=elements
    end

    def <<(e)
      @elements << e
    end
  end

  class Require < AstNode
    attr_accessor :filename
    def initialize str
      @filename=str
    end
  end

  class Str < AstNode
    attr_accessor :tok
    def initialize tok
      @tok=tok
    end
  end

  class Ident < AstNode
    attr_accessor :token
    def initialize token=nil
      @token=token
    end

    def str
      token.val
    end

    def ==(str)
      token.val==str
    end
  end

  class Circuit < AstNode
    attr_accessor :name,:inputs,:outputs,:sigs,:body
    attr_accessor :params
    attr_accessor :symtable
    def initialize name=nil,parameters=[],inputs=[],outputs=[],sigs=[],body=nil
      @name,@params=name,parameters
      @inputs,@outputs=inputs,outputs
      @sigs=sigs
      @body=body
    end
  end

  class Input < AstNode
    attr_accessor :name,:type
    def initialize name,type=nil
      @name,@type=name,type
    end
  end

  class Output < AstNode
    attr_accessor :name,:type
    def initialize name,type=nil
      @name,@type=name,type
    end
  end

  class Sig < AstNode
    attr_accessor :name,:type
    def initialize name,type=nil
      @name,@type=name,type
    end
  end

  #================== types ================
  class Bit < AstNode
  end

  class Byte < AstNode
  end

  class Sbyte < AstNode
  end

  class Int < AstNode
    attr_accessor :tok
    def initialize tok
      @tok=tok
    end
  end

  class Uint < AstNode
    attr_accessor :tok
    def initialize tok
      @tok=tok
    end
  end

  class ArrayType < AstNode
    attr_accessor :size,:type
    def initialize size,type
      @size=size
      @type=type
    end
  end

  class ParameterizedType < AstNode
    attr_accessor :param,:type
    def initialize param,type
      @param,@type=param,type
    end
  end

  class UnknownParameter < AstNode
  end

  class Parameter < AstNode
    attr_accessor :expr
    def initialize expr
      @expr=expr
    end
  end
  #=============== Body =======================

  class Body < AstNode
    attr_accessor :stmts
    def initialize stmts=[]
      @stmts=stmts
    end

    def <<(e)
      @stmts << e
    end
  end

  class Assignment < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Mapping < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=[],rhs=nil
      @lhs,@rhs=lhs,rhs
    end

    def <<(e)
      @lhs << e
    end
  end

  #================ expressions ===============
  class Nary < AstNode
    attr_accessor :op,:exprs
    def initialize op=nil,exprs=[]
      @op,@exprs=op,exprs
    end
  end
  class Unary < AstNode
    attr_accessor :op,:expr
    def initialize op=nil,expr=nil
      @op,@expr=op,expr
    end
  end

  class Binary < AstNode
    attr_accessor :lhs,:op,:rhs
    def initialize lhs=nil,op=nil,rhs=nil
      @lhs,@op,@rhs=lhs,op,rhs
    end

    def exprs
      [lhs,rhs]
    end
  end

  class Ternary < AstNode
    attr_accessor :cond,:lhs,:rhs
    def initialize cond=nil,lhs=nil,rhs=nil
      @cond,@lhs,@rhs=cond,lhs,rhs
    end
  end


  class Call < AstNode
    attr_accessor :name,:actual_args
    def initialize name=nil,actual_args=[]
      @name,@actual_args=name,actual_args
    end

    def <<(e)
      @actual_args << e
    end
  end

  class Indexed < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Pointed < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs=nil,rhs=nil
      @lhs,@rhs=lhs,rhs
    end
  end

  class Parenth < AstNode
    attr_accessor :expr
    def initialize expr=nil
      @expr=expr
    end
  end

  class IntLit < AstNode
    attr_accessor :tok
    def initialize tok=nil
      @tok=tok
    end

    def to_i
      @tok.val.to_i
    end
  end

  class Reg < AstNode
    attr_accessor :expr,:init
    def initialize expr=nil,init=nil
      @expr=expr
      @init=init
    end
  end

  class Range < AstNode
    attr_accessor :lhs,:rhs
    def initialize lhs,rhs
      @lhs,@rhs=lhs,rhs
    end
  end
end
