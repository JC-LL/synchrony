
module RTL

  class Circuit
    attr_accessor :name,:ports,:components,:signals
    attr_accessor :wires,:params,:father
    attr_accessor :color
    @@id=0

    def initialize name=nil
      @id=@@id+=1
      @name||=self.class.to_s.sub("RTL::",'')+"_"+(@id).to_s
      @ports={:in=>[],:out=>[]}
      @signals=[]
      @components=[]
      @params={}
      @father=nil
      @wires=[]
      @color="cadetblue"
    end

    def inputs
      @ports[:in]
    end

    def outputs
      @ports[:out]
    end

    def port_with_name dir,name
      @ports[dir].find{|e| e.name==name}
    end

    def component_with_name name
      @components.find{|e| e.name==name}
    end

    def signal_with_name name
      @signals.find{|sig| sig.name==name}
    end

    def all_ports
      @ports.values.flatten
    end

    def add *elems
      elems.each do |e|
        puts "adding #{e.class} #{e.name} to circuit #{self.name}..." if $verbose
        case e
        when Signal
          @signals << e
          e.circuit=self
        when Port
          @ports[e.dir] << e
          e.circuit=self
        when Circuit
          e.father=self
          @components << e
        when Wire
          @wires << e
        else
          raise "Circuit.add unknow element '#{e}'"
        end
      end
    end

    def save_as filename
      #require 'yaml'
      File.open(filename,'w') do |f|
        f.puts Marshal.dump self
      end
    end

  end

  class Wire
    attr_accessor :name,:pin,:pout,:id
    @@id=0

    def initialize pin,pout,prefix="w"
      @@id+=1
      @id=@@id
      @name=prefix+"(#{@@id})"
      @pin,@pout=pin,pout
      if @pin.circuit.father
        @pin.circuit.father.add self
      elsif @pout.circuit.father
        @pout.circuit.father.add self
      else
        #in --> out directly on father !
      end
    end

    def Wire.reset
      @@id=0
    end

    def Wire.get_id
      @@id
    end
  end

  class Port
    attr_accessor :name,:dir,:circuit,:connections,:params

    def initialize name,dir
      @name,@dir=name,dir
      @connections=[]
      @params={}
    end

    def connect port,wire_prefix="w"
      puts "connecting #{self.circuit.name}.#{self.name} -> #{port.circuit.name}.#{port.name}" if $verbose
      unless @connections.find{|w| w.pout==port}
        @connections << w=Wire.new(self,port,wire_prefix)
        port.connections << w
      end
      raise "ERROR : connects to himsef" if self==port
    end

    def set_param h
      @params.merge!(h)
    end

    alias :component :circuit
    alias :connexions :connections
  end


  class Signal < Port # MIND ! We can connect to a signal !
    def initialize name
      super(name,:out)
    end
  end

  class Constant < Signal
    def initialize value
      super(value.to_s)
    end
  end

  # WARNING :
  # those elementary elements for circuit are much extended in file rtl_circuit.rb
end
