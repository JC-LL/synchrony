module Synchrony

  class TypeChecker < Visitor

    def check ast,args=nil
      ast.accept(self,args)
    end

    def visitRoot(root,args=nil)
      root.elements.each{|e| e.accept(self,args)}
      root
    end

    def visitRequire(req,args=nil)
      req.filename.accept(self,args)
      req
    end

    def visitCircuit(circuit,args=nil)
      info 1,"checking circuit #{circuit.name.str}"
      circuit.inputs.each{|input| input.accept(self,args)}
      circuit.outputs.each{|output| output.accept(self,args)}
      circuit.wires.each{|wire| wire.accept(self,args)}
      circuit.instances.each{|instance| instance.accept(self,args)}
      circuit.body.accept(self,args)
    end

    def visitSig(sig,args=nil)
      sig.type.accept(self,args)
      sig.init.accept(self,args) if sig.init
    end

    def visitInput(input,args=nil)
      visitSig(input,args)
    end

    def visitOutput(output,args=nil)
      visitSig(output,args)
    end

    def visitWire(wire,args=nil)
      visitSig(wire,args)
    end

    def visitType(type,args=nil)
      type.accept(self) #returns a str
    end

    def visitBit(bit,args=nil)
      bit.str
    end

    def visitBits(bits,args=nil)
      bits.str
    end

    def visitInt(int,args=nil)
      int.str
    end

    def visitUint(uint,args=nil)
      uint.str
    end

    def visitInstance(instance,args=nil)
      instance.name.accept(self,args)
      instance.model.accept(self,args)
    end

    def visitBody(body,args=nil)
      body.stmts.each{|stmt| stmt.accept(self,args)}
    end

    def visitMap(map,args=nil)
      map.call.accept(self,args)
    end

    def visitAssign(assign,args=nil)
      assign.lhs.accept(self,args)
      type=visitExpr(assign.rhs)
    end

    def visitCombAssign(comb_assign,args=nil)
      comb_assign.lhs.accept(self,args)
      comb_assign.rhs.accept(self,args)
    end

    def visitSeqAssign(seq_assign,args=nil)
      seq_assign.lhs.accept(self,args)
      seq_assign.rhs.accept(self,args)
    end

    def visitIdent(ident,args=nil)
      ident
    end

    def visitIntLit(int_lit,args=nil)
      int_lit.tok.val
    end

    def visitStrLit(str_lit,args=nil)
      str_lit.tok.val
    end

    def visitExpr expr, args=nil
      expr.accept(self,args)
    end

    def visitCondExpr(cond_expr,args=nil)
      cond_expr.cond.accept(self,args)
      cond_expr.lhs.accept(self,args)
      cond_expr.rhs.accept(self,args)
    end

    def visitBinary(binary,args=nil)
      binary.lhs.accept(self,args)
      binary.rhs.accept(self,args)
    end

    def visitUnary(unary,args=nil)
      unary.expr.accept(self,args)
    end

    def visitDotExpr(dot_expr,args=nil)
      dot_expr.lhs.accept(self,args)
      dot_expr.rhs.accept(self,args)
    end

    def visitParenth(parenth,args=nil)
      parenth.expr.accept(self,args)
    end

    def visitCall(call,args=nil)
      call.name.accept(self,args)
      call.args.each{|arg| arg.accept(self,args)}
    end

    def visitBitField(bit_field,args=nil)
      bit_field.expr.accept(self,args)
      bit_field.range.accept(self,args)
    end

    def visitRange(range,args=nil)
      range.lhs.accept(self,args)
      range.rhs.accept(self,args)
    end

    def visitConcat(concat  ,args=nil)
      concat.lhs.accept(self,args)
      concat.rhs.accept(self,args)
    end
  end
end
