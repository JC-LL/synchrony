module Synchrony

  class Resolver < Visitor

    attr_reader :nb_errors
    #================================================
    def resolve ast,args=nil
      @symtable=Symtable.new
      @nb_errors=0
      set_instrinsinc_funcs()
      ast.accept(self,args)
    end
    #================================================
    # Intrinsic functions are declared here.
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
    def set_instrinsinc_funcs
      info 1,"declaring intrinsic functions"
      funcs={}
      funcs["resize"]   = Func.create("resize"  ,{"arg" => Bits.new,"val" => Uint.new}, return_type=Bits.new)
      funcs["signed"]   = Func.create("signed"  ,{"arg" => Bits.new}, return_type=Bits.new)
      funcs["unsigned"] = Func.create("unsigned",{"arg" => Bits.new}, return_type=Bits.new)
      funcs.each do |name,func|
        info 2,"func #{name}"
        func.is_intrinsic=true
        try_set name,func
      end
    end

    def try_set str,obj,pos=[:na,:na]
      if @symtable.get(str)
        error_duplicate(str,pos)
      else
        @symtable.set(str,obj)
      end
    end

    def error_unknown_identifier ident
      info 2,"ERROR at #{ident.pos} : unknown identifier '#{ident.str}'"
      @nb_errors+=1
    end

    def error_duplicate str,pos
      info 2,"ERROR at #{pos} : duplicate identifier '#{str}'"
      @nb_errors+=1
    end

    def error_illegal_input_init input
      pos=input.init.tok.pos
      info 2,"ERROR at #{pos} : illegal init of input"
      @nb_errors+=1
    end

    def error_illegal_assignee assign
      info 2,"ERROR at #{pos} : illegal assignment '#{assign.str}'. Left-hand side assignee must be an input or wire."
      @nb_errors+=1
    end

    def error_erroneous_require req
      pos=req.filename.pos
      filename=req.filename.str
      info 2,"ERROR at #{pos} : erroneous require. File '#{filename}' not found."
      @nb_errors+=1
    end

    def error_port_named_not_found_in_instance_of dot_expr,model
      port_name=dot_expr.rhs.str
      instance_name=dot_expr.lhs.str
      pos=get_position(dot_expr)
      pos="at #{pos}" if pos
      info 2,"ERROR #{pos} : in '#{dot_expr.str}'. No port named '#{port_name}' in '#{instance_name}' (instance of '#{model.name.str}')"
      @nb_errors+=1
    end

    def error_dot_expr_input_cannot_be_assigned assign,dot_expr
      pos=get_position(assign)
      pos="at #{pos}" if pos
      info 2,"ERROR #{pos} : in assignment '#{assign.str}'. '#{dot_expr.str}' is an instance input. It cannot be read."
      @nb_errors+=1
    end

    def error_dot_expr_output_cannot_be_assigned assign,dot_expr
      pos=get_position(assign)
      pos="at #{pos}" if pos
      info 2,"ERROR #{pos} : in assignment '#{assign.str}'. '#{dot_expr.str}' is an instance output. It cannot be written."
      @nb_errors+=1
    end

    def error_instance_not_found map
      instance_name=map.call.name.str
      mapping=map.str.size < 30 ? map.str : map.str[0..30]+"...)"
      pos=get_position(map)
      pos="at #{pos}" if pos
      info 2,"ERROR #{pos} : in '#{mapping}'. Unknown instance '#{instance_name}'."
      @nb_errors+=1
    end

    def error_instance_model_not_found instance
      model=instance.model
      pos=get_position(instance)
      pos="at #{pos}" if pos
      info 2,"ERROR #{pos} : in instance declaration. Unknown model '#{model.str}'."
      @nb_errors+=1
    end

    def error_wrong_number_of_arguments_for_mapping map,expected_number
      mapping=map.str.size < 30 ? map.str : map.str[0..30]+"...)"
      pos=get_position(map)
      pos="at #{pos}" if pos
      info 2,"ERROR #{pos} : in '#{mapping}'. Wrong number of arguments (#{expected_number} expected, got #{map.call.args.size})"
      @nb_errors+=1
    end

    def error_already_mapped map
      ha_str=map.call.name.str
      pos=get_position(map)
      pos="at #{pos}"
      info 2,"ERROR #{pos} : '#{ha_str}' already mapped."
      @nb_errors+=1
    end

    def error_arg_th_should_be map,idx,kinds,actual_kind
      mapping=map.str.size < 30 ? map.str : map.str[0..30]+"...)"
      pos=get_position(map)
      pos="at #{pos}" if pos
      info 2,"ERROR #{pos} : in '#{mapping}'. Expected argument n°#{idx+1} should be one of #{kinds.join(',')}. Actual is #{actual_kind}."
      @nb_errors+=1
    end

    #================================================
    def visitRoot(root,args=nil)
      root.elements.each{|e| e.accept(self,args)}
    end

    # require is relative to pwd.
    # require "f" => a file "f.syc" must exist in the same directory where synchrony has been run.
    # This file will be then parsed.
    # A list of circuits it contains is then entered in the symbol table.
    def visitRequire(req,args=nil)
      full_filename=$pwd+"/"+req.filename.str+".syc"
      if File.exist?(full_filename)
        require_ast=Parser.new.parse(full_filename)
        circuits_defined=require_ast.elements.select{|element| element.instance_of?(Synchrony::Circuit)}
        #puts "number of circuits defined in #{full_filename} = #{circuits_defined.size}"
        circuits_defined.each do |circ|
          name=circ.name.str
          pos=circ.name.pos
          try_set(name,circ,pos)
        end
      else
        error_erroneous_require(req)
      end
    end

    def visitCircuit(circuit,args=nil)
      info 1,"checking circuit #{circuit.name.str}"
      cname=circuit.name.str
      pos=circuit.name.pos
      try_set(cname,circuit,pos)
      @symtable.new_scope # mind the position of this opening
      circuit.inputs.each{|input| input.accept(self,args)}
      circuit.outputs.each{|output| output.accept(self,args)}
      circuit.wires.each{|wire| wire.accept(self,args)}
      circuit.instances.each{|instance| instance.accept(self,args)}
      circuit.body.accept(self,args)
      @symtable.close_scope
    end

    def visitSig(sig,args=nil)
      str=sig.name.str
      pos=sig.name.pos
      try_set(str,sig,pos)
      sig.type.accept(self,args)
      sig.init.accept(self,args) if sig.init
    end

    def visitInput(input,args=nil)
      visitSig(input,args)
      if input.init # that is not legal !
        error_illegal_input_init(input)
      end
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

    # instance ha1 : ha
    def visitInstance(instance,args=nil)
      str=instance.name.str
      pos=instance.name.pos
      circuit=instance.model.accept(self,args)
      if circuit
        try_set(str,klone=circuit.clone,pos)     # "ha1" -> ha circuit model
        try_set(circuit.name.str,klone,pos)      # "ha" -> ha circuit model
      else
        error_instance_model_not_found(instance)
        return nil
      end
    end

    def visitBody(body,args=nil)
      body.stmts.each{|stmt| stmt.accept(self,args)}
    end

    # -check that the number of arguments is correct.
    # -check that the input arguments are either inputs, wires, literals or binary/unary expressions
    # -check that the output arguments are either outputs or wires or open
    def visitMap(map,args=nil)
      # map.call.accept(self,args)
      map.call.args.each{|arg| arg.accept(self,args)}
      #=====
      call_name_str=map.call.name.str
      @mapped||=[]
      if @mapped.include?(call_name_str)
        error_already_mapped(map)
      else
        @mapped << call_name_str
      end
      # find the circuit
      circuit=@symtable.get(call_name_str)
      if circuit
        ports=circuit.ports
        # check that the number of arguments is correct.
        if ports.size!=map.call.args.size
          error_wrong_number_of_arguments_for_mapping(map,expected_number=ports.size)
        end
        ports.each_with_index do |port,idx|
          case port
          when Input
            # check that the input arguments are either inputs, wires, literals or binary/unary expressions
            arg=map.call.args[idx]
            case arg
            when Ident
              ident=arg
              case ident.ref
              when Input, Wire
              else
                actual_kind=ident.ref.class.to_s.split("::").last.downcase
                error_arg_th_should_be(map,idx,[:input,:wire,:literal,:expression],actual_kind)
              end
            when Binary, Unary
            when IntLit
            else
              actual_kind=arg.class.to_s.split("::").last.downcase
              error_arg_th_should_be(map,idx,[:input,:wire,:literal,:expression],actual_kind)
            end
          when Output
            # check that the output arguments are either outputs or wires or open
            arg=map.call.args[idx]
            case arg
            when Ident
              ident=arg
              case ident.ref
              when Output, Wire
              else
                actual_kind=ident.ref.class.to_s.split("::").last.downcase
                error_arg_th_should_be(map,idx,[:wire,:output],actual_kind)
              end
            when Binary, Unary
            else
              actual_kind=arg.class.to_s.split("::").last.downcase
              error_arg_th_should_be(map,idx,[:wire,:output],actual_kind)
            end
          end
        end
      else
        error_instance_not_found(map)
        nil
      end
    end

    def visitAssign(assign,args=nil)
      assign.lhs.accept(self,args)
      assign.rhs.accept(self,args)

      # some read/write operation are not allowed in assignments :
      case assign.lhs
      when DotExpr # verify that the dot_expr.rhs  is not an output
        dot_expr=assign.lhs
        instance=dot_expr.lhs.accept(self,args)
        if instance
          # Find the (cloned) circuit  of the declared instance
          circuit=@symtable.get(instance.name.str)
          # Find a port named dot_expr.rhs in the model
          port_name=dot_expr.rhs.str
          #puts ".#{port_name} in #{circuit.name.str} ?"
          ports=circuit.inputs+circuit.outputs
          port=ports.find{|port| port.name.str==port_name}
          if port.instance_of?(Synchrony::Output)
            error_dot_expr_output_cannot_be_assigned(assign,dot_expr)
          end
        end
      end
      case dot_expr=assign.rhs
      when DotExpr # verify that the dot_expr.rhs is not an input
        instance=dot_expr.lhs.accept(self,args)
        if instance
          # Find the (cloned) circuit  of the declared instance
          circuit=@symtable.get(instance.name.str)
          # Find a port named dot_expr.rhs in the model
          port_name=dot_expr.rhs.str
          #puts ".#{port_name} in #{circuit.name.str} ?"
          ports=circuit.inputs+circuit.outputs
          port=ports.find{|port| port.name.str==port_name}
          if port.instance_of?(Synchrony::Input)
            error_dot_expr_input_cannot_be_assigned(assign,dot_expr)
          end
        end
      end

    end

    def visitCombAssign(comb_assign,args=nil)
      visitAssign(comb_assign)
    end

    def visitSeqAssign(seq_assign,args=nil)
      visitAssign(seq_assign)
    end

    def visitIdent(ident,args=nil)
      if obj=ident.ref
        return obj
      else
        str=ident.tok.val
        obj=@symtable.get(str)
        if obj
          ident.ref=obj
        else
          error_unknown_identifier(ident)
          return nil
        end
      end
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
      instance=dot_expr.lhs.accept(self,args)
      if instance
        # Find the (cloned) circuit  of the declared instance
        circuit=@symtable.get(instance.name.str)
        # Find a port named dot_expr.rhs in the model
        port_name=dot_expr.rhs.str
        #puts ".#{port_name} in #{circuit.name.str} ?"
        ports=circuit.inputs+circuit.outputs
        port=ports.find{|port| port.name.str==port_name}
        if port
          return port
        else
          error_port_named_not_found_in_instance_of(dot_expr,circuit)
        end
      end
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
