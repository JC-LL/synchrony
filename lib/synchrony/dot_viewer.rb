module Synchrony

  class DotViewer < PrettyPrinter

    def run root
      root.accept(self)
    end


    COLORS={
      GTECH_GATES => "fff5cc",
      GTECH_RTL   => "ebab71",
      Reg        => "115FFF"
    }

    def get_color component
      if component.is_a?(Reg)
        return COLORS[Reg]
      end
      if GTECH_GATES.include?(component.class)
        return COLORS[GTECH_GATES]
      end
      if GTECH_RTL.include?(component.class)
        return COLORS[GTECH_RTL]
      end
      return "8fe88e" # GREEN default (user instances)
    end

    def visitCircuit(circuit,with_types=false)
      dot=Code.new
      dot << "digraph {"
      dot.indent=2
      dot << "rankdir=LR;"
      dot.newline
      dot << "// style global"
      dot << "node [fontname=\"Helvetica\",fontsize=10];"
      dot.newline

      dot << "// inputs"
      dot << "{"
      dot.indent=4
      dot << "rank=same;"
      circuit.inputs.each do |port|
        pname=port.name.str
        dot << "#{port.object_id} [shape=circle,label=\"#{pname}\", style=filled, fillcolor=\"#cce5ff\"];"
      end
      dot.indent=2
      dot << "}"
      dot.newline

      dot << "// outputs"
      dot << "{"
      dot.indent=4
      dot << "rank=same;"
      circuit.outputs.each do |port|
        pname=port.name.str
        dot << "#{port.object_id} [shape=circle,label=\"#{pname}\", style=filled, fillcolor=\"#ffcccc\"];"
      end
      dot.indent=2
      dot << "}"
      dot.newline

      dot << "// wires"
      circuit.wires.each do |port|
        pname=port.name.str
        dot << "#{port.object_id} [shape=point,xlabel=\"#{pname}\", style=filled, fillcolor=\"#11dd00\"];"
      end
      dot.newline
      dot << "// constants"
      circuit.consts.each do |port|
        pname=port.name.str
        dot << "#{port.object_id} [shape=circle,label=\"#{pname}\", style=filled, fillcolor=\"#1100dd\"];"
      end
      dot.newline
      dot << "// literals"
      circuit.literals.each do |port|
        pname=port.name.to_s
        dot << "#{port.object_id} [shape=point,xlabel=\"#{pname}\", style=filled, fillcolor=\"#cccccc\"];"
      end


      circuit.components.each do |component|
        iname=component.name
        cname=component.class.name.split("::").last
        inputs=component.inputs.map{|port| pname=port.name.to_s ; "<#{pname}> #{pname}"}.join('|')
        outputs=component.outputs.map{|port| pname=port.name.to_s ; "<#{pname}> #{pname}"}.join('|')
        label="\"{{#{inputs}}|#{component.name}:#{cname}|{#{outputs}}}\""
        fill_color=get_color(component)
        dot << "#{iname} [shape=record,style=\"rounded,filled\",fillcolor=\"##{fill_color}\",label=#{label}];"
      end

      all_ports=[circuit.ports+circuit.wires+circuit.consts+circuit.components.map{|comp| comp.ports}].flatten.uniq

      all_ports.each do |source|
        source_name=source.name
        if with_types
          if type=source.type
            type=type.str
          else
            type=""
          end
        end
        if source.component!=circuit
          source_name="#{source.component.name.to_s}:#{source_name}"
        else
          source_name=source.object_id.to_s
        end
        source.sinks.each do |sink|
          sink_name=sink.name
          if sink.component!=circuit
            sink_name="#{sink.component.name.to_s}:#{sink_name}"
          else
            sink_name=sink.object_id.to_s
          end
          dot << "#{source_name} -> #{sink_name} [label=\"#{type}\"];"
        end
      end

      dot.indent=0
      dot << "}"
      dot.save_as "#{circuit.name.str}.dot"
    end
  end
end
