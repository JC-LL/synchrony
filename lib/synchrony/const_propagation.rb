module Synchrony

  class ConstPropagator < Visitor

    def propagate ast,args=1
      ast.accept(self,args)
    end

    def visitSig(sig,args=nil)
      if sig.init
        expr=sig.init.accept(self,args)
        sig.init=expr
      end
      sig
    end

    def visitCircuit(circuit,args=nil)
      #info args,"analyzing #{circuit.name.str}"
      circuit.inputs.each{|input| input.accept(self,args+1)}
      circuit.outputs.each{|output| output.accept(self,args+1)}
      circuit.consts.each{|const| const.accept(self,args+1)}
      circuit.wires.each{|wire| wire.accept(self,args+1)}
      circuit.instances.each{|instance| instance.accept(self,args+1)}
      circuit.body.accept(self,args+1)
      circuit
    end

    def visitConst(const,args=nil)
      #info args,"analyzing #{const.str}"
      const.expr=const.expr.accept(self,args+1)
      const
    end

    def visitAssign(assign,args=nil)
      #info args,"interpreting #{assign.str}"
      assign.lhs.accept(self,args)
      assign.rhs=assign.rhs.accept(self,args+1)
      assign
    end

    def visitCombAssign(comb_assign,args=nil)
      visitAssign(comb_assign,args)
    end

    def visitSeqAssign(seq_assign,args=nil)
      visitAssign(seq_assign,args)
    end

    def visitIdent(ident,args=nil)
      if (const=ident.ref).is_a?(Const)
        return const.expr
      end
      ident
    end

    def visitIntLit(int_lit,args=nil)
      int_lit
    end

    def visitCondExpr(cond_expr,args=nil)
      #info args,"interpreting #{cond_expr.str}"
      cond_expr.cond=cond_expr.cond.accept(self,args)
      cond_expr.lhs=cond_expr.lhs.accept(self,args)
      cond_expr.rhs=cond_expr.rhs.accept(self,args)
      case cond_expr.cond.str
      when "1"
        return cond_expr.lhs
      when "0"
        return cond_expr.rhs
      else
        return cond_expr
      end
    end

    def visitBinary(binary,level)
      #info level,"interpreting #{binary.str}"
      binary.lhs=binary.lhs.accept(self,level+1)
      binary.rhs=binary.rhs.accept(self,level+1)
      if binary.lhs.is_a?(IntLit) and binary.rhs.is_a?(IntLit)
        op=binary.op.type
        case op
        when :add
          val=binary.lhs.to_i + binary.rhs.to_i
        when :sub
          val=binary.lhs.to_i - binary.rhs.to_i
        when :mul
          val=binary.lhs.to_i * binary.rhs.to_i
        when :div
          if binary.rhs.to_i!=0
            val=binary.lhs.to_i / binary.rhs.to_i
          else
            #info 2,"ERROR at #{binary.pos} : dvision by zero in '#{binary.str}'"
          end
        when :mod
          if binary.rhs.to_i!=0
            val=binary.lhs.to_i % binary.rhs.to_i
          else
            #info 2,"ERROR at #{binary.pos} : division by zero in '#{binary.str}'"
          end
        end
        lit=IntLit.create(val)
        #info level,"result=#{lit.str}"
        return lit
      end
      binary
    end

    def flip_bits(num, bit_length = 64)
      # Create a mask with all bits set for the given length
      mask = (1 << bit_length) - 1
      # Flip bits using XOR
      num ^ mask
    end

    def visitUnary(unary,args=nil)
      expr=unary.expr.accept(self,args)
      if expr.is_a?(IntLit)
        val=expr.to_i
        op=unary.op.type
        case op
        when :add # +42
          return expr
        when :sub # -42
          return IntLit.create(-val)
        when :not # not(42)
          # flip all bits
          size_bits=unary.expr.type.nb_bits
          return IntLit.create(flip_bits(val,size_bits))
        end
      end
      unary.expr=expr
      unary
    end

    def visitDotExpr(dot_expr,args=nil)
      dot_expr
    end

    def visitParenth(parenth,args=nil)
      expr=parenth.expr.accept(self,args)
      case expr
      when IntLit
        return expr
      when Parenth
        return expr
      else
        parenth.expr=expr
        return parenth
      end
    end

    def visitCall(call,args=nil)
      call.name.accept(self,args)
      call.args=call.args.map{|arg| arg.accept(self,args)}
      call
    end

    def extract_bitfield(x, max, min)
      # Validate inputs
      raise ArgumentError, "max must be >= min" if max < min
      raise ArgumentError, "min must be >= 0" if min < 0

      # Calculate the number of bits to extract
      bit_count = max - min + 1

      # Create mask and extract
      mask = (1 << bit_count) - 1
      (x >> min) & mask
    end

    def visitBitField(bit_field,args=nil)
      bit_field.expr=bit_field.expr.accept(self,args)
      bit_field.range=bit_field.range.accept(self,args)
      case bit_field.expr
      when IntLit
        # 0x10110[3:1] 3 bits asked ==> IntLit.new(0b11) 2 bits returned
        val=bit_field.expr.to_i
        lhs=bit_field.range.lhs.to_i
        rhs=bit_field.range.rhs.to_i
        asked_range=lhs-rhs+1
        bitfield_val=extract_bitfield(val,lhs,rhs)
        lit=IntLit.create(bitfield_val)
        if asked_range!=lit.nb_bits
          #info 2, "WARNING : extracting bitfield #{bit_field.range.str} (#{asked_range} bits asked) returns here an integer literal on #{lit.nb_bits} bits, which may be suprising."
        end
        return lit
      end
      bit_field
    end

    def visitRange(range,args=nil)
      range.lhs=range.lhs.accept(self,args)
      range.rhs=range.rhs.accept(self,args)
      range
    end

    def visitConcat(concat  ,args=nil)
      concat.lhs=concat.lhs.accept(self,args)
      concat.rhs=concat.rhs.accept(self,args)
      if concat.lhs.is_a?(IntLit) and concat.rhs.is_a?(IntLit)
        #info 2, "NIY : concat of two int literals (may yield surprises)."
      end
      concat
    end
  end
end
