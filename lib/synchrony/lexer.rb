module Synchrony

  class Token
    attr_accessor :type,:val,:pos
    def initialize type,val,pos
      @type,@val,@pos=type,val,pos
    end

    def is_a? type
      @type==type
    end

    def to_s
      "<#{@type.to_s.ljust(10)},#{@val.ljust(10)},#{pos}>"
    end
  end

  class Lexer
    def lex filename
      tokens=[]
      lines=IO.readlines(filename).map(&:downcase).map(&:chomp)
      lines.each_with_index do |line,lineno|
        column=1
        lineno+=1
        while line.size>0
          pos=[lineno,column]
          case line
          when /^\s+/
            token=nil
          when /^#(.*)/
            token=Token.new(:comment,"comment",pos)
          when /^require\b/
            token=Token.new(:require,"require",pos)
          when /^circuit\b/
            token=Token.new(:circuit,"circuit",pos)
          when /^input\b/
            token=Token.new(:input,"input",pos)
          when /^output\b/
            token=Token.new(:output,"output",pos)
          when /^wire\b/
            token=Token.new(:wire,"wire",pos)
          when /^instance\b/
            token=Token.new(:instance,"instance",pos)
          when /^map\b/
            token=Token.new(:map,"map",pos)
          when /^end\b/
            token=Token.new(:end,"end",pos)
          when /^init\b/
            token=Token.new(:init,"init",pos)
          when /^bit\b/
            token=Token.new(:bit,"bit",pos)
          when /^bits\b/
            token=Token.new(:bits,"bits",pos)
          when /^int\b/
            token=Token.new(:int,$&,pos)
          when /^uint(\d+)?\b/
            token=Token.new(:uint,$&,pos)
          when /^or\b/
            token=Token.new(:or,"or",pos)
          when /^not\b/
            token=Token.new(:not,"not",pos)
          when /^and\b/
            token=Token.new(:and,"and",pos)
          when /^xor\b/
            token=Token.new(:xor,"xor",pos)
          when /^nor\b/
            token=Token.new(:nor,"nor",pos)
          when /^nand\b/
            token=Token.new(:nand,"nand",pos)
          when /^\./
            token=Token.new(:dot,"dot",pos)
          when /^\+\./
            token=Token.new(:addc,"+.",pos) # preserves carry
          when /^\+/
            token=Token.new(:add,"+",pos)
          when /^\-\./
            token=Token.new(:subc,"-.",pos) # preserves carry
          when /^\-/
            token=Token.new(:sub,"-",pos)
          when /^\*/
            token=Token.new(:mul,"*",pos)
          when /^\//
            token=Token.new(:div,"/",pos)
          when /^\<\</
            token=Token.new(:lshift,"<<",pos)
          when /^\>\>/
            token=Token.new(:rshift,">>",pos)
          when /^\,/
            token=Token.new(:comma,",",pos)
          when /^\=\=/
            token=Token.new(:eqeq,"==",pos)
          when /^\!\=/
            token=Token.new(:neq,"!=",pos)
          when /^\=/
            token=Token.new(:assign,"=",pos)
          when /^\<\~/
            token=Token.new(:cassign,"<~",pos)
          when /^\<\|/
            token=Token.new(:sassign,"<|",pos)
          when /^\:/
            token=Token.new(:colon,":",pos)
          when /^\?/
            token=Token.new(:qmark,"?",pos)
          when /^\~/
            token=Token.new(:tilde,"~",pos)
          when /^\(/
            token=Token.new(:lparen,"(",pos)
          when /^\)/
            token=Token.new(:rparen,")",pos)
          when /^\[/
            token=Token.new(:lbracket,"[",pos)
          when /^\]/
            token=Token.new(:rbracket,"]",pos)
          when /^(0[bh])?\d+/
            token=Token.new(:int_lit,$&,pos)
          when /^\"(.*)\"/
            token=Token.new(:str_lit,$1,pos)
          when /^\=\=/
            token=Token.new(:eq,"==",pos)
          when /^\!\=/
            token=Token.new(:neq,"!=",pos)
          when /^\>/
            token=Token.new(:gt,">",pos)
          when /^\>=/
            token=Token.new(:gte,">=",pos)
          when /^\</
            token=Token.new(:lt,"<",pos)
          when /^\<=/
            token=Token.new(:lte,"<=",pos)
          when /^[a-z][_a-z0-9]*/
            token=Token.new(:ident,$&,pos)
          else
            raise "lexical error at line #{lineno}, column #{column} :#{line}"
          end
          size=$&.size
          column+=size
          line=line[size..-1]
          if token
            #pp token
            tokens << token
          end
        end
      end
      tokens
    end
  end
end
