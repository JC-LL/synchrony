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
      expect :string_literal
    end

    def parse_circuit
      expect :circuit
      expect :ident
      parse_parameters
      while showNext.is_a? [:input,:output,:sig]
        case showNext.kind
        when :input
          parse_input
        when :output
          parse_output
        when :sig
          parse_sig
        else
          raise "unknown token '#{showNext}'"
        end
      end
      parse_body
      expect :end
    end

    def parse_parameters
      if showNext.is_a? :lbrace
        expect :lbrace
        expect :ident
        while showNext.is_a?(:comma)
          acceptIt
          expect :ident
        end
        expect :rbrace
      else
        return nil
      end
    end

    def parse_input
      #puts "parse_input"
      expect :input
      expect :ident
      while showNext.is_a? :comma
        acceptIt
        expect :ident
      end
      if showNext.is_a? :colon
        acceptIt
        parse_type
      else
        # bit
      end
    end

    def parse_output
      #puts "parse_output"
      expect :output
      expect :ident
      while showNext.is_a? :comma
        acceptIt
        expect :ident
      end
      if showNext.is_a? :colon
        acceptIt
        parse_type
      else
        # bit
      end
    end

    def parse_sig
      #puts "parse_sig"
      expect :sig
      expect :ident
      while showNext.is_a? :comma
        acceptIt
        expect :ident
      end
      if showNext.is_a? :colon
        acceptIt
        parse_type
      else
        # bit
      end
      if showNext.is_a? :eq
        parse_init
      end
    end

    def parse_init
      expect :eq
      parse_expr
    end

    def parse_type
      case showNext.kind
      when :bit,:int,:uint,:byte,:sbyte
        acceptIt
      else
        raise "unknow type : '#{showNext.val}'"
      end
      # array type :
      while showNext.is_a? :lbrack
        acceptIt
        parse_expr
        expect :rbrack
      end
      # parameterized type
      if showNext.is_a? :lbrace
        parse_type_parameter
      end
    end

    def parse_type_parameter
      expect :lbrace
      if showNext.is_a? :qmark
        acceptIt
      else
        parse_expr
      end
      expect :rbrace
    end

    def parse_body
      while showNext.is_not_a? :end
        case showNext.kind
        when :ident
          parse_assignement
        when :lbrace
          parse_step
        else
          raise "unknow statement line #{showNext.pos.first} : #{showNext}"
        end
      end
    end

    def parse_assignement
      parse_term
      while showNext.is_a?(:comma)
        acceptIt
        parse_term
      end
      expect :eq
      parse_expr
    end

    def parse_expr
      parse_concat
    end

    def parse_concat
      parse_logical
      while showNext.is_a? :concat
        acceptIt
        parse_logical
      end
    end

    def parse_logical
      parse_or
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
      parse_term_2
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
            parse_expr
            expect :rparen
          end
        when :dot2
          acceptIt
          parse_term_2
        end
      end
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
