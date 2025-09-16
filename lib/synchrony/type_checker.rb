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

    # check that the type of the actual argument is (strictly) the same as the formal argument.
    #  'strictly' because in visitCall, the formal argument could be wider (more generic) than the actual arg.
    def visitMap(map,args=nil)
      circuit=map.call.name.ref
      map.call.args.each_with_index do |actual_arg,idx|
        formal_arg=circuit.ports[idx]
        actual_type=actual_arg.ref.type
        formal_type=formal_arg.type
        unless actual_type.str==formal_type.str
          pos=get_position(map)
          case idx
          when 0
            idx_str="first"
          when 1
            idx_str="second"
          when 2
            idx_str="third"
          else
            idx_str="#{idx}-th"
          end
          info 2,"ERROR at #{pos} : type mismatch in map. Actual #{idx_str} argument '#{actual_arg.str}' has type '#{actual_arg.ref.type.str}' while expected is '#{formal_arg.type.str}'."
        end
      end
    end

    def visitAssign(assign,args=nil)
      pos=get_position(assign)
      type_lhs=assign.lhs.accept(self,args)
      type_rhs=visitExpr(assign.rhs)
      puts "bug" unless type_lhs
      puts "bug" unless type_rhs
      unless type_lhs.str==type_rhs.str
        info 2,"ERROR at #{pos} : type mismatch in '#{assign.str}' : #{type_lhs.str} <- #{type_rhs.str}"
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

    def visitExpr expr, args=nil
      expr.accept(self,args)
    end

    def visitCondExpr(cond_expr,args=nil)
      cnd_type=cond_expr.cond.accept(self,args)
      lhs_type=cond_expr.lhs.accept(self,args)
      rhs_type=cond_expr.rhs.accept(self,args)
    end

    def check_homogeneous(t1,t2,binary)
      pos=binary.pos
      if t1.class != t2.class
        info 2,"ERROR at #{pos} : heterogeneous types not allowed in binary expression '#{binary.str}' :: #{t1.str} #{binary.op.val} #{t2.str}."
        info 2,"WARNING at #{pos} : due to previous errors, further checks may be nonsense."
        info 2,"WARNING at #{pos} : prefer fixing previous errors before dealing with the following."
      end
    end

    def check_is_arithmetic binary
      t1=binary.lhs.accept(self)
      t2=binary.rhs.accept(self)
      pos=binary.pos
      unless [Uint,Int].include?(t1.class)
        info 2,"ERROR at #{pos} : arithmetic error in '#{binary.str}'. '#{binary.lhs.str}' is #{t1.str} but should be Int or Uint."
      end
      unless [Uint,Int].include?(t2.class)
        info 2,"ERROR at #{pos} : arithmetic error in '#{binary.str}'. '#{binary.rhs.str}' is #{t2.str} but should be Int or Uint."
      end
    end

    def visitBinary(binary,args=nil)
      pos=get_position(binary)
      lhs_type=binary.lhs.accept(self,args)
      rhs_type=binary.rhs.accept(self,args)
      n=lhs_type.nb_bits
      m=rhs_type.nb_bits
      ret_type=lhs_type.clone
      case binary.op.type
      when :and,:or,:xor,:nand,:nor
        check_homogeneous(lhs_type,rhs_type,binary)
        ret_type.nb_bits=[n,m].max
      when :addc,:subc # safe version. preserves carry
        check_homogeneous(lhs_type,rhs_type,binary)
        check_is_arithmetic(binary)
        ret_type.nb_bits=[n,m].max + 1
      when :add,:sub # VHDL-like
        check_homogeneous(lhs_type,rhs_type,binary)
        check_is_arithmetic(binary)
        ret_type.nb_bits=[n,m].max
      when :mul
        check_homogeneous(lhs_type,rhs_type,binary)
        check_is_arithmetic(binary)
        ret_type.nb_bits=n + m
      when :div
        check_homogeneous(lhs_type,rhs_type,binary)
        check_is_arithmetic(binary)
        ret_type.nb_bits=n
      when :lshift
        case rhs=binary.rhs
        when IntLit
          if (k=rhs.to_i) >= 0
            ret_type.nb_bits= n+k
          else
            ret_type.nb_bits= n
          end
        else
          ret_type.nb_bits= n
        end
      when :rshift
        case rhs=binary.rhs
        when IntLit
          if (k=rhs.to_i) >= 0
            ret_type.nb_bits= [1,n-k].max
          else
            ret_type.nb_bits= n
          end
        else
          ret_type.nb_bits= n
        end
      end
      ret_type
    end

    def visitUnary(unary,args=nil)
      expr_type=unary.expr.accept(self,args)
      ret_type=expr_type
      case unary.op.type
      when :add,:addc
      when :sub
        case expr_type
        when Int
          # ret_type already here
        when Uint
          info 2,"ERROR at #{pos} : type error in '#{unary.str}'. Cannot use '-' with type Uint. Convert explicitely to Int."
        when Bits
          info 2,"ERROR at #{pos} : type error in '#{unary.str}'. Cannot use '-' with type Bits."
          ret_type=expr_type #default in order to continue analysis.
        end
      when :subc
        expr_type.nb_bits+=1 #safe
      when :not
        # ret_type already here
      end
      ret_type
    end

    def visitDotExpr(dot_expr,args=nil)
      #info 2,"checking #{dot_expr.str}"
      model=dot_expr.lhs.ref
      actual_rhs_str=dot_expr.rhs.str
      port=model.ports.find{|port| port.name.str==actual_rhs_str}
      unless port
        info 2,"ERROR at #{pos} : unknown port named '#{actual_rhs_str}' in circuit #{model.name.str}."
      end
      return port.type
    end

    def visitParenth(parenth,args=nil)
      parenth.expr.accept(self,args)
    end

    def check_is_int_literal arg
      unless [Uint,Int].include?(arg.type.class)
        info 2,"ERROR at #{arg.pos} : argument should be a int literal. Actual is #{arg.str}"
      end
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
      #info 2,"checking call '#{call.str}'"
      pos=get_position(call)
      func_def=call.name.ref
      unless func_def
        info 2, "ERROR at #{pos} : unknown call to #{call.str}"
      end
      call.args.each_with_index do |actual_arg,idx|
        arg_type_actual=actual_arg.accept(self,args)
        #info 3,"arg n°#{idx} #{actual_arg.str}".ljust(20)+":: #{arg_type_actual.str}"
        arg_type_formal=(formal_arg=func_def.args[idx]).type
        if arg_type_actual.is_a?(arg_type_formal.class)
          unless arg_type_formal.nb_bits==:generic or arg_type_actual.nb_bits==arg_type_formal.nb_bits
            info 2, "ERROR at #{pos} : argument '#{actual_arg.str}' is of type #{arg_type_actual.str} which is not compatible with formal argument declared #{formal_arg.str}"
          end
        end
      end
      # deal with intrinsic functions
      case func_def.name.str
      when "resize"
        type=call.args[0].accept(self).clone
        type.nb_bits
        # ensure second argument is a int_literal
        snd_arg=call.args[1]
        #check_is_int_literal(snd_arg)
        nb_bits=snd_arg.str.to_i
        type.nb_bits=nb_bits
        return type
      when "to_int"
        # reminder : call.args[0].accept(self) ==> type
        nb_bits=call.args[0].accept(self).nb_bits
        return Int.new(nb_bits)
      when "to_uint"
        nb_bits=call.args[0].accept(self).nb_bits
        return Uint.new(nb_bits)
      when "to_bits"
        nb_bits=call.args[0].accept(self).nb_bits
        return Bits.new(nb_bits)
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
        info 2, "ERROR at #{pos} : '#{bit_field.str}' trying to access out of bounds of '#{bit_field.expr.str}' which is #{lhs_type.str} (bits #{max}..#{min})"
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
