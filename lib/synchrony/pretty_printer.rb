require_relative 'code'

module Synchrony

  class PrettyPrinter

    attr_accessor :code

    def initialize
      @verbose=true
      @verbose=false
    end

    def print ast
      begin
        code=Code.new
        code << "# pretty printing"
        code << ast.accept(self)
        puts code.finalize
      rescue Exception => e
        puts e.backtrace
        puts e
      end
    end

    def visitToken tok, args=nil
      tok.val
    end

    def visitRoot root,args=nil
      code=Code.new
      root.elements.each{|stmt| code << stmt.accept(self)}
      code
    end

    def visitRequire require_,args=nil
      fn=require_.filename.accept(self)
      "require #{fn}"
    end

    #======================================================
    def visitCircuit circ,args=nil
      code=Code.new
      name=circ.name.accept(self)
      code << "circuit #{name}"
      code.indent=2
      circ.inputs.each{|i|  code << i.accept(self)}
      circ.outputs.each{|o| code << o.accept(self)}
      circ.sigs.each{|sig|  code << sig.accept(self)}
      code << circ.body.accept(self)
      code.indent=0
      code << "end"
      code
    end

    def visitInput input,args=nil
      name=input.name.accept(self)
      type=input.type.accept(self)
      "input #{name} : #{type}"
    end

    def visitOutput output,args=nil
      name=output.name.accept(self)
      type=output.type.accept(self)
      "input #{name} : #{type}"
    end

    def visitSig sig,args=nil
      name=sig.name.accept(self)
      type=sig.type.accept(self)
      "input #{name} : #{type}"
    end

    #======================================================
    def visitBit bit,args=nil
      "bit"
    end

    def visitByte byte,args=nil
      "byte"
    end

    def visitSbyte sbyte,args=nil
      "sbyte"
    end

    def visitInt int,args=nil
      int.tok.accept(self)
    end

    def visitUint uint,args=nil
      uint.tok.accept(self)
    end

    def visitArrayType ary,args=nil
      size=ary.size.accept(self)
      type=ary.type.accept(self)
      "#{type}[#{size}]"
    end

    def visitParameterizedType ptype,args=nil
      param=ptype.param.accept(self)
      type=ptype.type.accept(self)
      "#{type}{#{param}}"
    end

    def visitUnknownParameter int,args=nil
      "{?}"
    end

    #=================body ================================
    def visitBody body,args=nil
      code=Code.new
      body.stmts.each{|stmt| code << stmt.accept(self)}
      code
    end

    def visitAssignment assign,args=nil
      lhs=assign.lhs.accept(self)
      rhs=assign.rhs.accept(self)
      "#{lhs} = #{rhs}"
    end

    def visitMapping mapping,args=nil
      list=[]
      mapping.lhs.each{|sig| list << sig.accept(self)}
      rhs=mapping.rhs.accept(self) #should be a call
      "#{list.join(',')}=#{rhs}"
    end

    #============== expressions ==================
    def visitBinary bin,args=nil
      lhs=bin.lhs.accept(self)
      op=bin.op
      op="_" if op==:concat
      rhs=bin.rhs.accept(self)
      "#{lhs} #{op} #{rhs}"
    end

    def visitUnary unary,args=nil
      unary.op
      unary.expr.accept(self)
    end

    #=================terms=========================
    def visitIdent ident,args=nil
      ident.token.val
    end

    def visitReg reg,args=nil
      e=reg.expr.accept(self)
      if reg.init
        init=reg.init.accept(self)
        init=",#{init}"
      end
      "reg(#{e}#{init})"
    end

    def visitCall call,args=nil
      name=call.name.accept(self)
      args=call.actual_args.map{|e| e.accept(self)}
      "#{name}(#{args.join(',')})"
    end

    def visitIndexed indexed,args=nil
      lhs=indexed.lhs.accept(self)
      rhs=indexed.rhs.accept(self)
      "#{lhs}[#{rhs}]"
    end

    def visitPointed pointed,args=nil
      lhs=pointed.lhs.accept(self)
      rhs=pointed.rhs.accept(self)
      "#{lhs}.#{rhs}"
    end

    def visitParenth parenth,args=nil
      e=parenth.expr.accept(self)
      "(#{e})"
    end

    def visitIntLit intlit,args=nil
      intlit.tok.val
    end

    def visitStr str,args=nil
      str
    end

    def visitRange range,args=nil
      lhs=range.lhs.accept(self)
      rhs=range.rhs.accept(self)
      "#{lhs}..#{rhs}"
    end

  end #def visitVisitor
end #module