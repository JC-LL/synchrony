
module Synchrony
  class Parser

    attr_accessor :tokens

    def showNext lookahead=1
      @tokens[lookahead-1]
    end

    def acceptIt
      #puts "consuming : #{showNext}"
      @tokens.shift
    end

    def expect kind
      if (actual=showNext.type)==kind
        acceptIt
      else
        pos=showNext.pos
        raise "syntax error at #{pos} : expecting token #{kind}. Got #{actual}"
      end
    end

    def lex filename
      @tokens=Lexer.new.lex(filename)
    end

    def remove_comments
      @tokens.reject!{|tok| tok.type==:comment}
    end

    def parse filename
      lex(filename)
      remove_comments
      root=Root.new
      while tokens.any?
        case showNext.type
        when :require
          root << parse_require
        when :circuit
          root << parse_circuit
        else
          pos=showNext.pos
          pp showNext
          raise "parsing error at #{pos} : expecting either 'require' or 'circuit'"
        end
      end
      pp root
    end

    def parse_require
      puts "parsing require"
      expect :require
      lit=StrLit.new(expect(:str_lit))
      Require.new(lit)
    end

    def parse_circuit
      puts "parsing circuit"
      circ=Circuit.new
      expect :circuit
      circ.name=Ident.new(expect(:ident))
      pp decls=parse_declarations()
      circ.inputs    = decls.select{|decl| decl.is_a?(Synchrony::Input)}
      circ.outputs   = decls.select{|decl| decl.is_a?(Synchrony::Output)}
      circ.wires     = decls.select{|decl| decl.is_a?(Synchrony::Wire)}
      circ.instances = decls.select{|decl| decl.is_a?(Synchrony::Instance)}
      circ.body      = parse_body()
      expect :end
      circ
    end

    def parse_declarations
      puts "parsing parse_declarations"
      decls=[]
      while [:input,:output,:wire,:instance].include?(showNext.type)
        case showNext.type
        when :input
          decls << parse_input()
        when :output
          decls << parse_output()
        when :wire
          decls << parse_wire()
        when :instance
          decls << parse_instance()
        end
      end
      decls.flatten!
      decls
    end

    SIG_h={
      :input  => Synchrony::Input,
      :output => Synchrony::Output,
      :wire   => Synchrony::Wire
    }

    def parse_sig tok_type
      ret=[]
      expect tok_type
      name=Ident.new(expect(:ident))
      ret << SIG_h[tok_type].new(name)
      while showNext.is_a?(:comma)
        acceptIt
        name=Ident.new(expect(:ident))
        ret << SIG_h[tok_type].new(name)
      end
      if showNext.is_a?(:colon)
        acceptIt
        type=parse_type
        ret.each{|sig| sig.type=type}
        if showNext.is_a?(:init)
          acceptIt
          init=IntLit.new(expect :int_lit)
          ret.each{|sig| sig.init=init}
        end
      end
      ret
    end

    def parse_input
      parse_sig(:input)
    end

    def parse_output
      parse_sig(:output)
    end

    def parse_wire
      parse_sig(:wire)
    end

    TYPE_h={
      :bits => Synchrony::Bit,
      :uint => Synchrony::Uint,
      :int  => Synchrony::Int,
    }

    def parse_type
      case kind=showNext.type
      when :bit
        acceptIt
        type=Bit.new
      when :bits,:int,:uint
        acceptIt
        type=TYPE_h[kind].new
        if showNext.is_a? :lparen
          expect :lparen
          tok=expect(:int_lit)
          type.nb_bits=tok.val.to_i
          expect :rparen
        else
          type.nb_bits=32
        end
      else
        pos = showNext.pos
        raise "syntax error at #{pos} : unknow type"
      end
      type
    end

    def parse_instance
      ret=[]
      expect :instance
      name=Ident.new(expect(:ident))
      ret << Instance.new(name)
      while showNext.is_a?(:comma)
        acceptIt
        name=Ident.new(expect(:ident))
        ret << instance=Instance.new(name)
      end
      if showNext.is_a?(:colon)
        acceptIt
        model=Ident.new(expect(:ident))
      end
      ret.each{|instance| instance.model=model}
      ret
    end

    def parse_body
      puts "parsing body"
      body=Body.new
      while !showNext.is_a? :end
        case showNext.type
        when :map
          body << parse_mapping
        else
          lhs=parse_expression
          case showNext.type
          when :assign,:cassign
            body << assign=parse_comb_assign()
          when :sassign
            body << assign=parse_seq_assign()
          when :map
            parse_mapping()
          else
            pos = showNext.pos
            raise "syntax error at #{pos} : unknown token for body statement. Got #{showNext.type} !"
          end
          assign.lhs=lhs
        end
      end
      body
    end

    def parse_mapping
      expect :map
      call=parse_factor
      map=Map.new(call)
    end

    def parse_comb_assign
      assign=CombAssign.new
      case showNext.type
      when :assign,:cassign
        acceptIt
      else
        raise "expecting either '=' or '<~' "
      end
      assign.rhs=parse_expression()
      assign
    end

    def parse_seq_assign
      assign=SeqAssign.new
      case showNext.type
      when :sassign
        acceptIt
      else
        raise "expecting <| "
      end
      assign.rhs=parse_expression()
      assign
    end

    def parse_expression
      #puts "parse_expression"
      parse_cmp
    end

    COMPARISONS=[:eqeq,:neq,:gt,:gte,:lt,:lte]
    def parse_cmp
      e1=parse_or
      if COMPARISONS.include?(showNext.type)
        op=acceptIt
        e2=parse_or
        e1=Binary.new(e1,op.type,e2)
      end
      return e1
    end

    def parse_or
      e1=parse_xor
      while showNext.is_a? :or
        acceptIt
        e2=parse_xor()
        e1=Binary.new(e1,:or,e2)
      end
      e1
    end

    def parse_xor
      e1=parse_and
      while showNext.is_a? :xor
        acceptIt
        e2=parse_and()
        e1=Binary.new(e1,:xor,e2)
      end
      e1
    end

    def parse_and
      e1=parse_shift()
      while showNext.is_a? :and
        acceptIt
        e2=parse_shift()
        e1=Binary.new(e1,:and,e2)
      end
      e1
    end

    def parse_shift
      e1=parse_arith
      while showNext.is_a? [:lshift,:rshift]
        tok=acceptIt
        e2=parse_arith()
        e1=Binary.new(e1,tok.type,e2,map)
      end
      e1
    end

    def parse_arith
      e1=parse_term()
      while [:add,:sub].include? showNext.type
        tok=acceptIt
        e2=parse_term()
        e1=Binary.new(e1,tok.type,e2)
      end
      return e1
    end

    def parse_term
      e1=parse_power()
      while [:mul,:div,:mod].include? showNext.type
        tok=acceptIt
        e2=parse_power()
        e1=Binary.new(e1,tok.type,e2)
      end
      return e1
    end

    def parse_power
      e1=parse_factor()
      while showNext.is_a?(:pow)
        tok=acceptIt
        e2=parse_factor()
        e1=Binary.new(e1,:pow,e2)
      end
      return e1
    end

    def parse_factor
      case showNext.type
      when :ident
        tok=acceptIt
        ret=Ident.new(tok)
        if showNext.type==:dot
          acceptIt
          rhs=parse_expression
          ret=DotExpr.new(ret,rhs)
        end
      when :int_lit
        tok=acceptIt
        IntLit.new(tok)
      when :sub,:add
        ret=parse_unary
      when :lparen
        ret=parse_parenth
      else
        raise "SYNTAX ERROR in term at #{showNext.pos}: #{showNext.val} (#{showNext.type})"
      end

      # fcall
      if showNext.is_a? :lparen
        acceptIt
        ret=Call.new(ret) #prev ret should be Ident
        while showNext.type!=:rparen
          ret.args << parse_expression
          if showNext.is_a? :comma
            acceptIt
          end
        end
        expect :rparen
      end

      # bitfield expression
      if showNext.is_a? :lbracket
        ret=parse_bitfield()
        ret.expr=ret
      end

      # conditional expression
      if showNext.is_a? :qmark
        ret=CondExpr.new(ret) #ret should be a Binary comparison
        acceptIt
        ret.lhs=parse_expression
        expect :colon
        ret.rhs=parse_expression
      end

      # concatenation
      while showNext.is_a? :ampersand
        acceptIt
        ret=Concat.new([ret])
        ret.elements << parse_expression
      end
      ret
    end

    def parse_parenth
      #puts "parsing_parenth"
      expect :lparen
      expr=parse_expression()
      expect :rparen
      Parenth.new(expr)
    end

    def parse_unary
      if [:add,:sub].include? showNext.type
        op=acceptIt.type
        e=parse_arith()
        return Unary.new(op,e)
      end
      nil
    end

    def parse_bitfield
      expect :lbracket
      bit_field=BitField.new
      bit_field.range=Synchrony::Range.new
      bit_field.range.lhs=parse_expression
      while showNext.type==:colon
        acceptIt
        bit_field.range.rhs=parse_expression
      end
      expect :rbracket
      bit_field
    end

  end
end
