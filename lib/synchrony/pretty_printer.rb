module Synchrony

  class PrettyPrinter < Visitor

    def print ast,args=nil
      puts "pretty printing ast"
      code=ast.accept(self,args)
      puts code.finalize
    end

    def visitRoot(root,args=nil)
      code=Code.new
      root.elements.each{|e| code << e.accept(self,args)}
      code
    end

    def visitRequire(req,args=nil)
      name=req.circuit_name.accept(self,args)
      "require #{name}"
    end

    def visitCircuit(circuit,args=nil)
      code=Code.new
      name=circuit.name.accept(self,args)
      code << "circuit #{name}"
      code.indent=2
      circuit.inputs.each{|input|       code << input.accept(self,args)}
      circuit.outputs.each{|output|     code << output.accept(self,args)}
      circuit.wires.each{|wire|         code << wire.accept(self,args)}
      circuit.instances.each{|instance| code << instance.accept(self,args)}
      code << circuit.body.accept(self,args)
      code.indent=0
      code << "end"
      code
    end

    def visitSig(sig,args=nil)
      name=sig.name.accept(self,args)
      type=sig.type.accept(self,args)
      if  sig.init
        val=sig.init.accept(self,args)
        init="= #{val}"
      end
      [name,type,init]
    end

    def visitInput(input,args=nil)
      name,type,init=visitSig(input,args)
      "input #{name} : #{type}"
    end

    def visitOutput(output,args=nil)
      name,type,init=visitSig(output,args)
      "output #{name} : #{type} #{init}"
    end

    def visitWire(wire,args=nil)
      name,type,init=visitSig(wire,args)
      "wire #{name} : #{type} #{init}"
    end

    def visitType(type,args=nil)
      type.accept(self)
    end

    def visitBit(bit,args=nil)
      "bit"
    end

    def visitBits(bits,args=nil)
      "bits(#{bits.nb_bits})"
    end

    def visitInt(int,args=nil)
      "int(#{int.nb_bits})"
    end

    def visitUint(uint,args=nil)
      "uint(#{uint.nb_bits})"
    end

    def visitInstance(instance,args=nil)
      name =instance.name.accept(self,args)
      model=instance.model.accept(self,args)
      "instance #{name} : #{model}"
    end

    def visitBody(body,args=nil)
      code=Code.new
      body.stmts.each{|stmt| code << stmt.accept(self,args)}
      code
    end

    def visitMap(map,args=nil)
      call=map.call.accept(self,args)
      "map #{call}"
    end

    def visitCombAssign(comb_assign,args=nil)
      lhs=comb_assign.lhs.accept(self,args)
      rhs=comb_assign.rhs.accept(self,args)
      "#{lhs} = #{rhs}"
    end

    def visitSeqAssign(seq_assign,args=nil)
      lhs=seq_assign.lhs.accept(self,args)
      rhs=seq_assign.rhs.accept(self,args)
      "#{lhs} <| #{rhs}"
    end

    def visitIdent(ident,args=nil)
      ident.tok.val
    end

    def visitIntLit(int_lit,args=nil)
      int_lit.tok.val
    end

    def visitStrLit(str_lit,args=nil)
      str_lit.tok.val
    end

    def visitCondExpr(cond_expr,args=nil)
      cond=cond_expr.cond.accept(self,args)
      lhs=cond_expr.lhs.accept(self,args)
      rhs=cond_expr.rhs.accept(self,args)
      "#{cond} ? #{lhs} : #{rhs}"
    end

    def visitBinary(binary,args=nil)
      lhs=binary.lhs.accept(self,args)
      rhs=binary.rhs.accept(self,args)
      "#{lhs} #{binary.op.val} #{rhs}"
    end

    def visitUnary(unary,args=nil)
      expr=unary.expr.accept(self,args)
      "#{unary.op.val} #{expr}"
    end

    def visitDotExpr(dot_expr,args=nil)
      lhs=dot_expr.lhs.accept(self,args)
      rhs=dot_expr.rhs.accept(self,args)
      "#{lhs}.#{rhs}"
    end

    def visitParenth(parenth,args=nil)
      expr=parenth.expr.accept(self,args)
      "(#{expr})"
    end

    def visitCall(call,args=nil)
      name=call.name.accept(self,args)
      args=call.args.map{|arg| arg.accept(self,args)}
      "#{name}(#{args.join(',')})"
    end

    def visitBitField(bit_field,args=nil)
      expr=bit_field.expr.accept(self,args)
      range=bit_field.range.accept(self,args)
      "#{expr}[#{range}]"
    end

    def visitRange(range,args=nil)
      lhs=range.lhs.accept(self,args)
      rhs=range.rhs.accept(self,args)
      if lhs==rhs
        return lhs
      else
        return "#{lhs}:#{rhs}"
      end
    end

    def visitConcat(concat  ,args=nil)
      lhs=concat.lhs.accept(self,args)
      rhs=concat.rhs.accept(self,args)
      "#{lhs}~#{rhs}"
    end
  end
end
