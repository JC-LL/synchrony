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
    def pos
      @tok.pos
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
    attr_accessor :filename
    def initialize filename
      @filename=filename
    end
  end
  #========================
  class Circuit < AstNode
    attr_accessor :name,:ports,:wires,:instances,:body
    def initialize name=nil,ports=[],wires=[],instances=[],body=nil
      @name,@ports,@body=name,ports,instances,body
    end

    def inputs
      @inputs||=@ports.select{|port| port.instance_of?(Synchrony::Input)}
    end

    def outputs
      @outputs||=@ports.select{|port| port.instance_of?(Synchrony::Output)}
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

  class Arg < Sig
  end
  #============================
  class Type < AstNode
    attr_accessor :nb_bits
    def initialize nb_bits=:generic
      @nb_bits=nb_bits
    end
  end

  # class Integer < Type
  # end

  class Bits < Type
  end

  class Bit < Bits
    def initialize
      super(1)
    end
  end

  class Int < Bits
  end

  class Uint < Bits
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
    attr_accessor :ref # for contextual analysis / name resolution
  end

  class IntLit < SingleTokenNode
    attr_reader :type
    def initialize tok
      super(tok)
      if tok.val.to_i < 0
        @type=Int.new(bits_required)
      else
        @type=Uint.new(bits_required)
      end
    end

    # Pour un entier négatif n < 0 : il faut représenter n dans l’intervalle [−2^(k−1), 2^(k−1)−1].
    # Donc on cherche le plus petit k tel que n >= -2^(k-1).
    def bits_required
      n=self.tok.val.to_i
      if n >= 0
        return 1 if n == 0
        Math.log2(n).floor + 1
      else
        k = 1
        # augmenter k jusqu’à ce que n soit représentable en complément à deux
        while n < -(2**(k-1))
          k += 1
        end
        k
      end
    end
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

#=============================================
  class Func < AstNode
    attr_accessor :is_intrinsic
    attr_accessor :name
    attr_accessor :args
    attr_accessor :return_type
    attr_accessor :body
    def initialize(name,args=[],return_type=nil,body=nil)
      @name=name
      @args=args
      @return_type=return_type
      @body=body
    end

    def self.create name,args,return_type=nil
      func=Func.new(name.to_ident)
      args.each do |name_str,type|
        func.args << Arg.new(name_str.to_ident,type)
      end
      func.return_type=return_type
      func
    end
  end

end
