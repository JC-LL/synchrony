module Synchrony

  # Elaborator generates in memory an interconnect of components via their i/o ports.
  # This can be viewed as an RTL synthesis.
  class Elaborator < Visitor
    def elaborate root
      root.accept(self)
      root
    end

    def visitCircuit(circuit,args=nil)
      @circuit=circuit
      circuit.body.accept(self,args)
      circuit
    end

    def visitMap(map,args=nil)
      comp=map.call.name.accept(self) #returns a reference to the instanciated circuit
      @circuit.components << comp
      map.call.args.each_with_index do |arg,idx|
        pb=comp.ports[idx]
        pa=arg.accept(self,args)
        case pb
        when Input
          pa.connect(pb)
        when Output
          pb.connect(pa)
        end
      end
      map
    end

    def visitCombAssign(comb_assign,args=nil)
      port_l=comb_assign.lhs.accept(self,args)
      port_r=comb_assign.rhs.accept(self,args)
      port_r.connect(port_l)
    end

    def visitSeqAssign(seq_assign,args=nil)
      port_l=seq_assign.lhs.accept(self,args)
      port_r=seq_assign.rhs.accept(self,args)
      @circuit.components << reg=Reg.new
      d=reg.get_port_named(:d)
      q=reg.get_port_named(:q)
      port_r.connect(d)
      q.connect(port_l)
      port_l
    end

    def visitIdent(ident,args=nil)
      ident.ref
    end

    def visitIntLit(int_lit,args=nil)
      @circuit << int_lit.port #WARNING
      int_lit.port
    end

    def visitCondExpr(cond_expr,args=nil)
      port_cond=cond_expr.cond.accept(self,args)
      port_lhs =cond_expr.lhs.accept(self,args)
      port_rhs =cond_expr.rhs.accept(self,args)
      @circuit.components << mux=Mux2.new
      cmd=mux.get_port_named(:cmd)
      i1=mux.get_port_named(:i1)
      i2=mux.get_port_named(:i2)
      f=mux.get_port_named(:f)
      port_cond.connect(cmd)
      port_lhs.connect(i1)
      port_rhs.connect(i2)
      f
    end

    OP_CIRCUIT_H={
      "=="   => CmpEq,
      "+"    => Add,
      "-"    => Sub,
      "*"    => Mul,
      "/"    => Div,
      "mod"  => Mod,
      "or"   => Or2,
      "and"  => And2,
      "xor"  => Xor2,
      "not"  => Inv,
    }

    def visitBinary(binary,args=nil)
      lhs_port=binary.lhs.accept(self,args)
      rhs_port=binary.rhs.accept(self,args)
      @circuit.components << comp=OP_CIRCUIT_H[binary.op.val].new
      i1=comp.get_port_named(:i1)
      i2=comp.get_port_named(:i2)
      f=comp.get_port_named(:f)
      lhs_port.connect(i1)
      rhs_port.connect(i2)
      f
    end

    def visitUnary(unary,args=nil)
      port_expr=unary.expr.accept(self,args)
      @circuit.components << comp=OP_CIRCUIT_H[binary.op.val].new
      e=comp.get_port_named(:i)
      f=comp.get_port_named(:f)
      port_expr.connect(e)
      f
    end

    def visitDotExpr(dot_expr,args=nil)
      dot_expr.ref #established by resolver
    end

    def visitParenth(parenth,args=nil)
      port=parenth.expr.accept(self,args)
      port
    end

    def visitCall(call,args=nil)
      call.name.accept(self,args)
      call.args.each{|arg| arg.accept(self,args)}
      call
    end

    def visitBitField(bit_field,args=nil)
      bit_field.expr.accept(self,args)
      bit_field.range.accept(self,args)
      bit_field
    end

    def visitRange(range,args=nil)
      range.lhs.accept(self,args)
      range.rhs.accept(self,args)
      range
    end

    def visitConcat(concat  ,args=nil)
      concat.lhs.accept(self,args)
      concat.rhs.accept(self,args)
      concat
    end
  end
end
