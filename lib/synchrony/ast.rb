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

    # find probable line/column
    # recursive descent from node to instance variables.
    def pos
      visitor=Visitor.new
      visitor.get_position(self)
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
    @@id=-1
    attr_accessor :name,:ports,:consts,:wires,:instances,:body
    attr_accessor :components

    def initialize name=nil,ports=[],wires=[],instances=[],body=nil
      @@id+=1 #risky (using Synchrony "require" : what occurs ?)
      @id=@@id
      name||="u#{@id}" #?
      @name,@ports,@body=name,ports,instances,body
      @components=[]
    end

    def inputs
      @inputs||=@ports.select{|port| port.instance_of?(Synchrony::Input)}
    end

    def outputs
      @outputs||=@ports.select{|port| port.instance_of?(Synchrony::Output)}
    end

    def literals
      @literals||=@ports.select{|port| !port.instance_of?(Synchrony::Input) and !port.instance_of?(Synchrony::Output)}
    end

    def << e
      case e
      when Port
        @ports << e
        e.component=self
      when Circuit
        @instances << e
      end
    end

    def get_port_named name
      @ports.find{|port| port.name.to_s==name.to_s}
    end
  end


  #========================
  class Sig < AstNode
    attr_accessor :name,:type,:init
    def initialize name=nil,type=nil,init=nil
      @name,@type,@init=name,type,init
    end
  end

  class Port < Sig
    attr_accessor :component # for netlist
    attr_accessor :source,:sinks
    def initialize name=nil,type=nil
      super(name,type)
      @source=nil
      @sinks=[]
    end

    def connect sink
      @sinks << sink unless @sinks.include?(sink)
      sink.source=self
    end

    def to_s
      "#{component.name.to_s}.#{name}"
    end
  end

  class Input < Port
  end

  class Output < Port
  end

  class Wire < Port # clever ?
  end

  class Const < Port # clever ?
    attr_accessor :name,:type,:expr
    def initialize(name,type,expr)
      @name,@type,@expr=name,type,expr
    end
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

    def to_s
      @tok.val
    end
  end

  class Literal < SingleTokenNode
    attr_accessor :port
    def initialize tok
      super(tok)
      name=tok.val
      @port=Port.new(name)
    end
  end

  class IntLit < Literal
    attr_reader :type
    def initialize tok
      super(tok)
      case tok.val.downcase
      when /0b([10]+)/
        nbits=$1.size
      when /0x([0-9a-f]+)/
        nbits=$1.size*4
      when /(\d+)'([bxd])([a-f0-9]+)/
        nbits=$1.to_i
        # WARNING : NYI we should check that $1,$2 and $3 are coherent together.
      else #plain integer 42,-7,...
        n=tok.val.to_i
        nbits=IntLit.bits_required(n)
      end
      if tok.val.to_i < 0
        @type=Int.new(nbits)
      else
        @type=Uint.new(nbits)
      end
    end

    def IntLit.bits_required n
      if n >= 0
        return 1 if n == 0
        return Math.log2(n).floor + 1
      else
        k = 1
        # augmenter k jusqu’à ce que n soit représentable en complément à deux
        while n < -(2**(k-1))
          k += 1
        end
        return k
      end
    end

    def IntLit.create val
      tok=Token.create_int_lit(val)
      IntLit.new(tok)
    end
  end

  class StrLit < SingleTokenNode
  end

  class Expr < AstNode
    attr_accessor :type
  end

  class CondExpr < Expr
    attr_accessor :cond,:lhs,:rhs
    def initialize cond=nil,lhs=nil,rhs=nil
      @cond,@lhs,@rhs=cond,lhs,rhs
    end
  end

  class Binary < Expr
    attr_accessor :lhs,:op,:rhs
    def initialize lhs,op,rhs
      @lhs,@op,@rhs=lhs,op,rhs
    end
  end

  class Unary < Expr
    attr_accessor :op,:expr

    def initialize op,expr
      @op,@expr=op,expr
    end
  end

  class DotExpr < Expr
    attr_accessor :lhs,:rhs
    def initialize lhs,rhs
      @lhs,@rhs=lhs,rhs
    end
  end

  class Parenth < Expr
    attr_accessor :expr
    def initialize expr
      @expr=expr
    end
  end

  class Call < Expr
    attr_accessor :name,:args
    def initialize name,args=[]
      @name,@args=name,args
    end
  end

  class BitField < Expr
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

  class Concat < Expr
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
