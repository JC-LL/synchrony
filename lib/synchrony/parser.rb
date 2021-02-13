# coding: utf-8
require_relative 'generic_parser'
require_relative 'ast'
require_relative 'lexer'

module Synchrony

  class Parser < GenericParser

    attr_accessor :options
    attr_accessor :lexer,:tokens
    attr_accessor :basename,:filename

    def initialize options={}
      @options=options
    end

    def lex filename
      unless File.exists?(filename)
        raise "ERROR : cannot find file '#{filename}'"
      end
      begin
        str=IO.read(filename).downcase
        tokens=Lexer.new.tokenize(str)
        tokens=tokens.select{|t| t.class==Token} # filters [nil,nil,nil]
        tokens.reject!{|tok| tok.is_a? [:comment,:newline,:space]}
        return tokens
      rescue Exception=>e
        unless options[:mute]
          puts e.backtrace
          puts e
        end
        raise "an error occured during LEXICAL analysis. Sorry. Aborting."
      end
    end

    def parse filename
      begin
        @tokens=lex(filename)
        puts "......empty file !" if tokens.size==0
        root=Root.new([])
        while @tokens.any?
          case showNext.kind
          when :comment
            root << acceptIt
          when :require
            root << parse_require
          when :circuit
            root << parse_circuit
          else
            raise "got #{showNext}"
          end
        end
      rescue Exception => e
        unless options[:mute]
          puts e.backtrace
          puts e
        end
        raise
      end
      root
    end

    def parse_require
      expect :require
      tok=expect :string_literal
      Require.new(Str.new(tok))
    end

    def parse_circuit
      circuit=Circuit.new
      expect :circuit
      circuit.name=Ident.new(expect :ident)
      circuit.params=parse_parameters
      while showNext.is_a? [:input,:output,:sig]
        case showNext.kind
        when :input
          circuit.inputs << parse_input
          circuit.inputs.flatten!
        when :output
          circuit.outputs << parse_output
          circuit.outputs.flatten!
        when :sig
          circuit.sigs << parse_sig
          circuit.sigs.flatten!
        else
          raise "unknown token '#{showNext}'"
        end
      end
      circuit.body=parse_body
      expect :end
      circuit
    end

    def parse_parameters
      params=[]
      if showNext.is_a? :lbrace
        expect :lbrace
        params << Ident.new(expect :ident)
        while showNext.is_a?(:comma)
          acceptIt
          params << Ident.new(expect :ident)
        end
        expect :rbrace
      end
      params
    end

    def parse_input
      inputs=[]
      expect :input
      inputs << Input.new(Ident.new(expect :ident))
      while showNext.is_a? :comma
        acceptIt
        inputs << Input.new(Ident.new(expect :ident))
      end
      if showNext.is_a? :colon
        acceptIt
        type=parse_type
      else
        type=Bit.new
      end
      inputs.each{|i| i.type=type}
      inputs
    end

    def parse_output
      outputs=[]
      expect :output
      outputs << Output.new(Ident.new(expect :ident))
      while showNext.is_a? :comma
        acceptIt
        outputs << Output.new(Ident.new(expect :ident))
      end
      if showNext.is_a? :colon
        acceptIt
        type=parse_type
      else
        type=Bit.new
      end
      outputs.each{|o| o.type=type}
      outputs
    end

    def parse_sig
      sigs=[]
      expect :sig
      sigs << Sig.new(Ident.new(expect :ident))
      while showNext.is_a? :comma
        acceptIt
        sigs << Sig.new(Ident.new(expect :ident))
      end
      if showNext.is_a? :colon
        acceptIt
        type=parse_type
      else
        type=Bit.new
      end
      # if showNext.is_a? :eq
      #   parse_init
      # end
      sigs.each{|sig| sig.type=type}
      sigs
    end

    def parse_init
      expect :assign
      parse_expr
    end

    def parse_type
      case showNext.kind
      when :bit,:int,:uint,:byte,:sbyte
        tok=acceptIt
        case tok.kind
        when :bit
          type=Bit.new
        when :uint
          type=Uint.new(tok)
        when :int
          type=Int.new(tok)
        when :byte
          type=Byte.new
        when :sbyte
          type=Sbyte.new
        end
      else
        raise "unknow type : '#{showNext.val}'"
      end
      # array type :
      while showNext.is_a? :lbrack
        acceptIt
        e=parse_expr
        expect :rbrack
        type=ArrayType.new(size=e,type)
      end
      # parameterized type
      if showNext.is_a? :lbrace
        parameter=parse_type_parameter
        type=ParameterizedType.new(parameter,type)
      end
      type
    end

    def parse_type_parameter
      expect :lbrace
      if showNext.is_a? :qmark
        acceptIt
        return UnknownParameter.new
      else
        return parse_expr
      end
      expect :rbrace
    end

    def parse_body
      body=Body.new
      while showNext.is_not_a? :end
        case showNext.kind
        when :ident
          body << parse_assignement
        when :lbrace
          body << parse_step
        else
          raise "unknow statement line #{showNext.pos.first} : #{showNext}"
        end
      end
      body
    end

    def parse_assignement
      lhs=parse_term
      if showNext.is_a?(:comma)
        # positional mapping
        mapping=Mapping.new
        mapping << lhs
        while showNext.is_a?(:comma)
          acceptIt
          mapping << parse_term
        end
      end
      expect :assign
      rhs=parse_expr
      if mapping
        mapping.rhs=rhs
        return mapping
      end
      Assignment.new(lhs,rhs)
    end

    def parse_expr
      parse_concat
    end

    def parse_concat
      lhs=parse_logical
      while showNext.is_a? :concat
        acceptIt
        rhs=parse_logical
        lhs=Binary.new(lhs,:concat,rhs)
      end
      lhs
    end

    def parse_logical
      e=parse_or
      if showNext.is_a? :qmark
        e=parse_ternary(e)
      end
      e
    end

    def parse_ternary e
      expect :qmark
      e1=parse_expr
      expect :colon
      e2=parse_expr
      Ternary.new(e,e1,e2)
    end

    def parse_or
      l=parse_and
      while showNext.is_a? [:or,:xor]
        op=acceptIt.kind
        r=parse_and
        l=Binary.new(l,op,r)
      end
      l
    end

    def parse_and
      l=parse_comp
      while showNext.is_a? :and
        op=acceptIt.kind
        r=parse_comp
        l=Binary.new(l,op,r)
      end
      l
    end

    def parse_comp
      l=parse_arith
      while showNext.is_a? [:eq,:neq,:gt,:gte,:lt,:lte]
        op=acceptIt.kind
        r=parse_arith
        l=Binary.new(l,op,r)
      end
      l
    end

    def parse_arith
      parse_add
    end

    def parse_add
      e1=parse_mult
      while showNext.is_a? [:add,:sub,:bitwise_or,:bitwise_xor]
        op=acceptIt.kind
        e2=parse_mult
        e1=Binary.new(e1,op,e2)
      end
      e1
    end

    def parse_mult
      e1=parse_term
      while showNext.is_a? [:mul,:div,:bitwise_and,:rshift,:lshift]
        op=acceptIt.kind
        e2=parse_term
        e1=Binary.new(e1,op,e2)
      end
      e1
    end

    def parse_name
      Ident.new expect(:ident)
    end

    def parse_term
      term=parse_term_2
      while showNext.is_a? [:lbrack,:dot,:dollar,:dot2]
        case showNext.kind
        when :lbrack
          acceptIt
          e=parse_arith
          expect :rbrack
          term=Indexed.new(term,e)
        when :dot
          acceptIt
          e=parse_term
          term=Pointed.new(term,e)
        when :dollar
          acceptIt
          if showNext.is_a? :lparen
            acceptIt
            init=parse_expr
            expect :rparen
          end
          term=Reg.new(term,init)
        when :dot2
          acceptIt
          lhs=term
          rhs=parse_term_2
          term=Range.new(lhs,rhs)
        end
      end
      term
    end

    def parse_term_2
      term=nil
      case showNext.kind
      when :ident
        term=name=parse_name
        if showNext.is_a? :lparen
          acceptIt
          args=[]
          args << parse_expr
          while showNext.is_a? :comma
            acceptIt
            args << parse_expr
          end
          expect :rparen
          term=Call.new(name,args)
          if name=="reg" # '==' redefined for Ident !
            if args.size > 2
              raise "ERROR : reg may have 1..2 arguments [expr,init] but not more !"
            end
            expr,init=args[0..1]
            term=Reg.new(expr,init)
          end
        end
      when :int_literal
        tok=acceptIt
        term=IntLit.new(tok)
      when :lparen
        term=parse_parenth
      when :sub,:not,:excl,:bitwise_not
        term=parse_unary
      else
        raise "wrong expression on line #{showNext.pos.first}. Got '#{showNext.val}'"
      end
      term
    end

    def parse_parenth
      expect :lparen
      e=parse_expr
      expect :rparen
      Parenth.new(e)
    end

    def parse_unary
      if showNext.is_a? [:excl,:not,:sub,:bitwise_not]
        op=acceptIt.kind
        op=:not if op==:excl
        e=parse_expr
        return Unary.new(op,e)
      else
        raise "expecting unary expression : '!', 'not', '-' or '~' "
      end
    end

    def parse_step
      expect :lbrace
      while showNext.is_not_a?(:rbrace)
        parse_assignement
      end
      expect :rbrace
      if showNext.is_a? :dollar
        acceptIt
      end
    end
  end
end
