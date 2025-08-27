module Synchrony

  #================================================
  # The type system is :
  #        ___  bit
  #       /
  # bits  ____  signed
  #       \___  unsigned
  #
  #================================================
  # when a function is called like resize(x,32)
  # the type checker must :
  # - get the declared type of x. lets say unsigned(16)
  # - verify that unsigned exists
  # - verify that 1st arg unsigned(16) inherits Bits(:unknown)
  # - verify that 2nd arg 32 (IntLit) has type Integer.
  # - in the case of RESIZE precisely, generate exact return type Unsigned(32)
  # - return type Unsigned(32)
  #================================================

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
    end

    def visitBody(body,args=nil)
      body.stmts.each{|stmt| stmt.accept(self,args)}
    end

    def visitMap(map,args=nil)
      map.call.accept(self,args)
    end

    def visitAssign(assign,args=nil)
      pos=get_position(assign)
      type_lhs=assign.lhs.accept(self,args)
      type_rhs=visitExpr(assign.rhs)
      unless type_lhs.str==type_rhs.str
        info 2,"ERROR at #{pos} : left/right types mismatch in '#{assign.str}' : #{type_lhs.str} <- #{type_rhs.str}"
      end
    end

    def visitCombAssign(comb_assign,args=nil)
      visitAssign(comb_assign)
    end

    def visitSeqAssign(seq_assign,args=nil)
      visitAssign(seq_assign)
    end

    def visitIdent(ident,args=nil)
      #puts "visiting #{ident.str} at #{get_position(ident)}"
      ident.ref.type
    end

    def visitIntLit(int_lit,args=nil)
      int_lit.type
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

    #================================================
    # when a function is called like resize(x,32)
    # the type checker must :
    # - get the declared type of x. lets say unsigned(16)
    # - verify that unsigned exists
    # - verify that 1st arg unsigned(16) inherits Bits(u)
    # - verify that 2nd arg 32 (IntLit) that has type Uint(6) inherits  Uint(u)
    # - in the case of RESIZE precisely, generate exact return type Unsigned(32)
    # - return type Unsigned(32)
    #================================================
    def visitCall(call,args=nil)
      #info 2,"visiting call '#{call.str}'"
      func_def=call.name.ref
      if func_def
        #info 3, "func definition found"
        #puts func_def.str
      end
      call.args.each_with_index do |actual_arg,idx|
        arg_type_actual=actual_arg.accept(self,args)
        #info 3,"arg n°#{idx} #{actual_arg.str}".ljust(20)+":: #{arg_type_actual.str}"
        arg_type_formal=func_def.args[idx].type
        if arg_type_actual.is_a?(arg_type_formal.class)
          if arg_type_formal.nb_bits==:generic or arg_type_actual.nb_bits==arg_type_formal.nb_bits
            #info 4, "compatible with #{arg_type_formal.str}"
          else
            info 4, "ERROR : not compatible with #{arg_type_formal.str}"
          end
        end
      end
      case func_def.name.str
      when "resize"
        nb_bits=call.args[1].str.to_i
        ret_type=call.args[0].accept(self).clone
        ret_type.nb_bits=nb_bits
        return ret_type
      when "signed"
        nb_bits=call.args[0].ref.type.nb_bits
        ret_type=Int.new
        ret_type.nb_bits=nb_bits
        return ret_type
      when "unsigned"
        nb_bits=call.args[0].ref.type.nb_bits
        ret_type=Uint.new
        ret_type.nb_bits=nb_bits
        return ret_type
      end
    end

    # - check that access indicated is not out of bounds
    # - returns the final Bits type with correct number of bits.
    def visitBitField(bit_field,args=nil)
      pos=get_position(bit_field)
      lhs_type=bit_field.expr.accept(self,args)
      range=0..lhs_type.nb_bits-1 # mind the counter-intuitive order !!!
      max=range.max
      min=range.min
      l,r=bit_field.range.accept(self,args)
      if l<0 or r<0
        info 2, "ERROR at #{pos} : '#{bit_field.str}' bit fields bounds must be natural numbers."
      end
      unless range.include?(l) and range.include?(r)
        info 2, "ERROR at #{pos}: '#{bit_field.str}' trying to access out of bounds #{max}..#{min} of '#{bit_field.expr.str}' declared as #{lhs_type.str} "
      end
      nb_bits=l-r+1
      case nb_bits
      when 0
        info 2,"ERROR : #{bitfield.str} amounts to 0 bits."
      when 1
        return Bit.new
      else
        return Bits.new(nb_bits)
      end
    end

    def visitRange(range,args=nil)
      l=range.lhs.str.to_i
      r=range.rhs.str.to_i
      [l,r]
    end

    def visitConcat(concat  ,args=nil)
      lhs_type=concat.lhs.accept(self,args)
      rhs_type=concat.rhs.accept(self,args)
      nb_bits=lhs_type.nb_bits + rhs_type.nb_bits
      return Bits.new(nb_bits)
    end
  end
end
