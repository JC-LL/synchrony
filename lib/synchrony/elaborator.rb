require_relative 'transformer'
require_relative 'circuit_base'
require_relative 'circuit_rtl'
require_relative 'circuit_drawer'

module Synchrony

  class Elaborator < Transformer

    def initialize
      $verbose=true
    end

    # we suppose that the circuit has been checker in a previous pass.
    def elaborate ast
      begin
        ast.accept(self)
      rescue Exception => e
        puts e.backtrace
        puts e
      end
    end

    def visitRequire req,args=nil
      @lib||={}
      @clone_id={}
      original=req.filename.str
      info 2,"requiring #{original}"
      filename=original.gsub(/\"/,'')
      # load corresponding file, but suffixed by .lib (marshalled version)
      lib=File.basename(filename,'.lib')+".lib"
      if File.exist?(lib)
        #@lib[filename]=YAML.load(File.read(lib))
        @lib[filename]=Marshal.load(File.read(lib))
        info 3,"loaded #{lib} successfully"
        @clone_id[filename]=0
      else
        info 3,"ERROR : you required file #{original}, but its corresponding \"#{lib}\" does not exist. Check compilation order."
      end
    end

    def visitCircuit circ,args=nil
      # a circuit yields a 'netlist' (RTL::Circuit)
      @netlist=RTL::Circuit.new(name=circ.name.str)
      info 2,"elaborating '#{name}'"
      @symtable={} # simply-scoped symbol table may suffice.
      $verbose=false
      collect_symbols(circ)
      circ.body.accept(self)
      @netlist.save_as "#{name}.lib"
      info 2,"netlist for '#{name}' built successfully"
      info 2,"generating graphviz : #{circ.name.str}.dot"
      @netlist.print_info
      @netlist.to_dot
    end

    def collect_symbols circ
      info 3,"collecting symbols"
      #puts "# inputs : #{circ.inputs.size}"
      circ.inputs.each do |input|
        name=input.name.str
        @netlist.add port=RTL::Port.new(name,:in)
        @symtable[name]=port
      end
      #puts "# outputs : #{circ.outputs.size}"
      circ.outputs.each do |output|
        name=output.name.str
        @netlist.add port=RTL::Port.new(name,:out)
        @symtable[name]=port
      end
      #puts "# sigs : #{circ.sigs.size}"
      circ.sigs.each do |sig|
        name=sig.name.str
        @netlist.add sig=RTL::Signal.new(name)
        @symtable[name]=sig
      end
    end

    def visitBody body,args=nil
      body.stmts.each do |stmt|
        info 3,"dealing with #{stmt.str}"
        assign=mapping=stmt
        case stmt
        when Assignment
          port_sink=@symtable[assign.lhs.str]
          port_source=build(assign.rhs)
          port_source.connect port_sink
        when Mapping
          call=mapping.rhs
          call_name=call.name.str
          component=instanciate_component(call_name)
          @netlist.add component
          formal_inputs=component.inputs
          formal_outputs=component.outputs
          call.actual_args.each_with_index do |arg,idx|
            port_source=build(arg)
            port_sink=formal_inputs[idx]
            port_source.connect port_sink
          end
          mapping.lhs.each_with_index do |sig,idx|
            port_source=formal_inputs[idx]
            port_sink=build(sig)
            port_source.connect port_sink
          end
        end
      end
    end

    def instanciate_component name
      if component=@lib[name]
        info 4,"found component '#{name}' in library. Good."
        clone=component.clone
        clone.name+="_#{@clone_id[name]+=1}"
        return clone
      else
        info 4,"ERROR : can't find component named '#{call_name}' in library. Did you compiled it ?"
      end
    end

    def build expr
      ident=unary=binary=ternary=expr
      case expr
      when Ident
        return @symtable[ident.str]
      when Unary
        info 4,"build #{expr.str}"
        op=binary.op.to_s.capitalize
        klass=Object.const_get("RTL::"+op+"Gate")
        @netlist.add comp=klass.new
        i1=build(unary.expr)
        gate_i1=comp.port_with_name(:in,'i1')
        i1.connect gate_i1
        return comp.port_with_name(:out,"f")
      when Binary
        info 4,"build #{expr.str}"
        op=binary.op.to_s.capitalize
        klass=Object.const_get("RTL::"+op+"Gate")
        @netlist.add comp=klass.new
        i1=build(binary.rhs)
        i2=build(binary.lhs)
        gate_i1=comp.port_with_name(:in,'i1')
        gate_i2=comp.port_with_name(:in,'i2')
        i1.connect gate_i1
        i2.connect gate_i2
        return comp.port_with_name(:out,"f")
      when Ternary
        info 4,"build #{expr.str}"
        raise "NIY : ternary"
      else
        raise "ERROR : don't know how to build #{expr.str}"
      end
    end
  end
end
