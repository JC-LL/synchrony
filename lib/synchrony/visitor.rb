require_relative 'code'

module Synchrony

  class Visitor

    attr_accessor :code

    def initialize
      @verbose=true
      @verbose=false
    end

    def visit ast
      begin
      ast.accept(self)
      rescue Exception => e
        puts e.backtrace
        puts e
      end
    end

    def visitToken tok, args=nil
    end

    def visitRoot root,args=nil
      root.elements.each{|stmt| stmt.accept(self)}
    end

    def visitRequire require_,args=nil
      require_.filename.accept(self)
    end

    #======================================================
    def visitCircuit circ,args=nil
      circ.name.accept(self)
      circ.inputs.each{|i| i.accept(self)}
      circ.outputs.each{|o| o.accept(self)}
      circ.sigs.each{|sig| sig.accept(self)}
      circ.body.accept(self)
    end

    def visitInput input,args=nil
      input.name.accept(self)
      input.type.accept(self)
    end

    def visitOutput output,args=nil
      output.name.accept(self)
      output.type.accept(self)
    end

    def visitSig sig,args=nil
      sig.name.accept(self)
      sig.type.accept(self)
    end

    #======================================================
    def visitBit bit,args=nil
    end

    def visitByte byte,args=nil
    end

    def visitSbyte sbyte,args=nil
    end

    def visitInt int,args=nil
      int.tok.accept(self)
    end

    def visitUint uint,args=nil
      uint.tok.accept(self)
    end

    def visitArrayType ary,args=nil
      ary.size.accept(self)
      ary.type.accept(self)
    end

    def visitParameterizedType ptype,args=nil
      ptype.param.accept(self)
      ptype.type.accept(self)
    end

    def visitUnknownParameter int,args=nil
    end

    #=================body ================================
    def visitBody body,args=nil
      body.stmts.each{|stmt| stmt.accept(self)}
    end

    def visitAssignment assign,args=nil
      assign.lhs.accept(self)
      assign.rhs.accept(self)
    end

    def visitMapping mapping,args=nil
      mapping.lhs.each{|sig| sig.accept(self)}
      mapping.rhs.accept(self) #should be a call
    end

    #============== expressions ==================

    def visitUnary unary,args=nil
      unary.op
      unary.expr.accept(self)
    end

    def visitBinary bin,args=nil
      bin.lhs.accept(self)
      bin.op
      bin.rhs.accept(self)
    end

    def visitTernary ternary,args=nil
      ternary.cond.accept(self)
      ternary.lhs.accept(self)
      ternary.rhs.accept(self)
    end

    #=================terms=========================
    def visitIdent ident,args=nil
      ident.token.accept(self)
    end

    def visitReg reg,args=nil
      reg.expr.accept(self)
      if reg.init
        init=reg.init.accept(self)
      end
    end

    def visitCall call,args=nil
      call.name.accept(self)
      call.actual_args.each{|e| e.accept(self)}
    end

    def visitIndexed indexed,args=nil
      indexed.lhs.accept(self)
      indexed.rhs.accept(self)
    end

    def visitPointed pointed,args=nil
      pointed.lhs.accept(self)
      pointed.rhs.accept(self)
    end

    def visitParenth parenth,args=nil
      parenth.expr.accept(self)
    end

    def visitIntLit intlit,args=nil
      intlit.tok.val
    end

    def visitStr str,args=nil
      str
    end

    def visitRange range,args=nil
      range.lhs.accept(self)
      range.rhs.accept(self)
    end

  end #def visitVisitor
end #module
