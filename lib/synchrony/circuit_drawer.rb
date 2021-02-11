class String
  def last n
    self[-n..-1] || self
  end
end

module RTL

  class Circuit
    require_relative 'info_printer'
    include InfoPrinter

    def to_dot
      str = []

      str <<  "digraph G {\n"
      str << "   graph [rankdir = LR];\n"
      #str << "   node[shape=record];\n"

      @components.each do |c|
        inputs_str ="{"+c.ports[:in].collect{|e| "<#{e.name}>#{e.name}"}.join("|")+"}"
        outputs_str="{"+c.ports[:out].collect{|e| "<#{e.name}>#{e.name}"}.join("|")+"}"
        color=c.color
        str << "   #{c.name}[ shape=record; style=filled ; color=#{color} ; label=\"{ #{inputs_str}| #{c.name} | #{outputs_str} }\"];"
      end

      @ports[:in].each do |p|
        str << "   #{p.name}[shape=cds xlabel=\"#{p.name}\"];"
      end

      @ports[:out].each do |p|
        str << "   #{p.name}[shape=cds xlabel=\"#{p.name}\"];"
      end

      @signals.each do |sig|
        str << " #{sig.name}[shape=point ; xlabel=\"#{sig.name}\"];"
      end

      @ports[:in].each do |p|
        p.connections.each do |wire|
          pin=wire.pout
          c=p.circuit==self ? "#{p.name}" : "#{p.circuit.name}:#{p.name}"
          if not(pin.circuit.name==self.name and pin.name==c)
            str << "   #{c} -> #{pin.circuit.name}:#{pin.name}[ label=\"#{wire.name}\"];"
          end
        end
      end

      @signals.each do |sig|
        sig.connections.each do |wire|
          pin=wire.pout
          c=sig.circuit==self ? "#{sig.name.to_s}" : "#{sig.circuit.name.to_s}:#{p.name.to_s}"
          unless (pin.circuit.name.to_s==self.name and pin.name.to_s==c)
            str << "   #{c} -> #{pin.circuit.name}:#{pin.name}[ label=\"#{wire.name}\"]; /* tag2 */"
          end
        end
      end

      @components.each do |c|
        c.ports[:out].each do |p|
          p.connections.each do |wire| #pin
            pout=wire.pout
            c=pout.circuit==self ? "#{pout.name}" : "#{pout.circuit.name}:#{pout.name}"
            if c!=p.circuit.name+":"+p.name
              str << "   #{p.circuit.name}:#{p.name} -> #{c}[label=\"#{wire.name}\"]; /* tag3 */"
            end
          end
        end
      end
      str << "}"

      full_text=str.join("\n")

      # ======= hacking ========================
      info 3,"graphviz : applying renaming"
      full_text.gsub!("#{self.name}:",'')
      full_text.gsub!(/\'/,'')
      full_text.gsub!(/\./,'_')
      # =========================================
      File.open("#{self.name}.dot",'w') do |f|
        f.puts full_text
      end
    end

    def print_info
      puts "#{self.name}".center(40,'+')
      puts "inputs : (#{inputs.size})"
      inputs.each{|i|  puts "\t- #{i.name}"}
      puts "outputs : (#{outputs.size})"
      outputs.each{|i|  puts "\t- #{i.name}"}
      puts "sub-components : (#{components.size})"
      components.each{|i|  puts "\t- #{i.name}"}
    end

    def view
      system("rm -rf #{name}.dot #{name}.png")
      to_dot()
      system("dot -Tpng #{name}.dot -o #{name}.png ; eog #{name}.png")
    end

  end




end
