require_relative 'code'
require_relative 'info_printer'

module Synchrony

  # here we transform an AST into another AST.
  # we don't use Marshalling.

  class Transformer

    include InfoPrinter

    attr_accessor :code

    def initialize
      @ind=-2
      @verbose=true
      @verbose=false
    end

    def transform ast
      begin
        ast.accept(self)
      rescue Exception =>e
        puts e
        puts e.backtrace
      end
    end

    alias :visit :transform

    def new_tmp
      $tmp_id||=0
      tok=Token.create_id "$"+$tmp_id.to_s
      $tmp_id+=1
      Ident.new(tok)
    end

    def new_ident
      new_tmp
    end

    def reset_new_ident
      @tmp_id=0
    end

    def visitToken tok, args=nil
      Token.new(tok.kind,tok.val,tok.pos)
    end

    def visitRoot root,args=nil
      stmts=root.elements.map{|e| e.accept(self)}
      Root.new(stmts)
    end

    def visitRequire require_,args=nil
      str=require_.filename.accept(self)
      Require.new(str)
    end

    #======================================================
    def visitCircuit circ,args=nil
      name=circ.name.accept(self)
      params=circ.params.map{|i| i.accept(self)}
      inputs=circ.inputs.map{|i| i.accept(self)}
      outputs=circ.outputs.map{|o| o.accept(self)}
      sigs=circ.sigs.map{|sig| sig.accept(self)}
      body=circ.body.accept(self)
      Circuit.new(name,params,inputs,outputs,sigs,body)
    end

    def visitInput input,args=nil
      name=input.name.accept(self)
      type=input.type.accept(self)
      Input.new(name,type)
    end

    def visitOutput output,args=nil
      name=output.name.accept(self)
      type=output.type.accept(self)
      Output.new(name,type)
    end

    def visitSig sig,args=nil
      name=sig.name.accept(self)
      type=sig.type.accept(self)
      Sig.new(name,type)
    end

    #======================================================
    def visitBit bit,args=nil
      Bit.new
    end

    def visitByte byte,args=nil
      Byte.new
    end

    def visitSbyte sbyte,args=nil
      Sbyte.new
    end

    def visitInt int,args=nil
      tok=int.tok.accept(self)
      Int.new(tok)
    end

    def visitUint uint,args=nil
      tok=uint.tok.accept(self)
      Uint.new(tok)
    end

    def visitArrayType ary,args=nil
      size=ary.size.accept(self)
      type=ary.type.accept(self)
      ArrayType.new(size,type)
    end

    def visitParameterizedType ptype,args=nil
      param=ptype.param.accept(self)
      type=ptype.type.accept(self)
      ParameterizedType.new()
    end

    def visitUnknownParameter up,args=nil
      UnknownParameter.new
    end

    #=================body ================================
    def visitBody body,args=nil
      new_stmts=body.stmts.map{|stmt| stmt.accept(self)}
      Body.new(new_stmts)
    end

    def visitAssignment assign,args=nil
      lhs=assign.lhs.accept(self)
      rhs=assign.rhs.accept(self)
      Assignment.new(lhs,rhs)
    end

    def visitMapping mapping,args=nil
      lhs=mapping.lhs.each{|sig| sig.accept(self)}
      rhs=mapping.rhs.accept(self) #should be a call
      Mapping.new(lhs,rhs)
    end

    #============== expressions ==================

    def visitUnary unary,args=nil
      op=unary.op
      expr=unary.expr.accept(self)
      Unary.new(op,expr)
    end

    def visitBinary bin,args=nil
      lhs=bin.lhs.accept(self)
      op=bin.op
      rhs=bin.rhs.accept(self)
      Binary.new(lhs,op,rhs)
    end

    def visitTernary ternary,args=nil
      cond=ternary.cond.accept(self)
      lhs=ternary.lhs.accept(self)
      rhs=ternary.rhs.accept(self)
      Ternary.new(cond,lhs,rhs)
    end

    #=================terms=========================
    def visitIdent ident,args=nil
      tok=ident.token.accept(self)
      Ident.new(tok)
    end

    def visitReg reg,args=nil
      e=reg.expr.accept(self)
      if reg.init
        init=reg.init.accept(self)
      end
      Reg.new(e,init)
    end

    def visitCall call,args=nil
      name=call.name.accept(self)
      args=call.actual_args.each{|e| e.accept(self)}
      Call.new(name,args)
    end

    def visitIndexed indexed,args=nil
      lhs=indexed.lhs.accept(self)
      rhs=indexed.rhs.accept(self)
      Indexed.new(lhs,rhs)
    end

    def visitPointed pointed,args=nil
      lhs=pointed.lhs.accept(self)
      rhs=pointed.rhs.accept(self)
      Pointed.new(lhs,rhs)
    end

    def visitParenth parenth,args=nil
      e=parenth.expr.accept(self)
      Parenth.new(e)
    end

    def visitConcat concat,args=nil
      exprs=concat.exprs.map{|e| e.accept(self)}
      Concat.new(exprs)
    end

    def visitIntLit intlit,args=nil
      tok=intlit.tok.accept(self)
      IntLit.new(tok)
    end

    def visitStr str,args=nil
      tok=str.tok.accept(self)
      Str.new(tok)
    end

    def visitRange range,args=nil
      lhs=range.lhs.accept(self)
      rhs=range.rhs.accept(self)
      Range.new(lhs,rhs)
    end

  end #def visitVisitor
end #module
