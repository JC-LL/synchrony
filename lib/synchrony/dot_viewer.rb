module Synchrony

  class DotViewer < PrettyPrinter

    def run root
      root.accept(self)
    end

    def visitCircuit(circuit,args=nil)
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
      dot << "rank=same;"
      circuit.inputs.each do |port|
        pname=port.name.str
        dot << "#{port.object_id} [shape=circle,label=\"#{pname}\", style=filled, fillcolor=\"#cce5ff\"];"
      end
      dot << "}"
      dot.newline

      dot << "// outputs"
      dot << "{"
      dot << "rank=same;"
      circuit.outputs.each do |port|
        pname=port.name.str
        dot << "#{port.object_id} [shape=circle,label=\"#{pname}\", style=filled, fillcolor=\"#ffcccc\"];"
      end
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
        dot << "#{iname} [shape=record,style=\"rounded,filled\",fillcolor=\"#fff5cc\",label=#{label}];"
      end

      all_ports=[circuit.ports+circuit.wires+circuit.consts+circuit.components.map{|comp| comp.ports}].flatten.uniq

      all_ports.each do |source|
        source_name=source.name
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
          dot << "#{source_name} -> #{sink_name};"
        end
      end

      dot.indent=0
      dot << "}"
      dot.save_as "#{circuit.name.str}.dot"
    end
  end
end
