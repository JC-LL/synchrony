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

  class Ident < AstNode
    attr_accessor :token
    def initialize token=nil
      @token=token
    end
  end

  class Binary < AstNode
    attr_accessor :lhs,:op,:rhs
    def initialize lhs=nil,op=nil,rhs=nil
      @lhs,@op,@rhs=lhs,op,rhs
    end
  end

  class Binary < AstNode
    attr_accessor :lhs,:op,:rhs
    def initialize lhs=nil,op=nil,rhs=nil
      @lhs,@op,@rhs=lhs,op,rhs
    end
  end

  class Unary < AstNode
    attr_accessor :op,:expr
    def initialize op=nil,expr=nil
      @op,@expr=op,expr
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

  class Arg < AstNode
    attr_accessor :name,:type
    def initialize name=nil,type=nil
      @name,@type=name,type
    end
  end

  class ArgRef < AstNode
    attr_accessor :name,:type
    def initialize name=nil,type=nil
      @name,@type=name,type
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
end
