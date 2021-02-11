require_relative 'circuit_base'

module RTL

  class BitSlice < Circuit
    attr_accessor :slice
    def initialize slice=0..0
      super()
      add Port.new("i",:in)
      add Port.new("f",:out)
      @slice=slice
    end
  end

  class BitGroup < Circuit
    attr_accessor :nb_parts
    def initialize
      super()
      @nb_parts=0
      add Port.new("f",:out)
    end

    def add port
      @nb_parts+=1
      super port
    end
  end

  class Reg < Circuit
    def initialize
      super()
      add Port.new("D",:in)
      add Port.new("Q",:out)
      @color="darkorange"
    end
  end

  class Mux < Circuit
    attr_accessor :arity
    def initialize
      super()
      @arity=0
      add Port.new("i0",:in)
      add Port.new("i1",:in)
      add Port.new("sel",:in)
      add Port.new("f",:out)
    end

    def add port
      @arity+=1
      super port
    end
  end

  class UnaryGate < Circuit
    def initialize name=nil
      super(name)
      add Port.new("i",:in)
      add Port.new("f" ,:out)
    end
  end

  class NotGate < UnaryGate
  end

  class BinaryGate < Circuit
    def initialize name=nil
      super(name)
      add Port.new("i1",:in)
      add Port.new("i2",:in)
      add Port.new("f" ,:out)
    end
  end

  class AndGate < BinaryGate
  end

  class OrGate < BinaryGate
  end

  class XorGate < BinaryGate
  end

  class EqGate < BinaryGate
  end

  class NaryGate < Circuit
    attr_accessor :arity
    def initialize name=nil
      super(name)
      @arity=0
      add Port.new("f" ,:out)
    end

    def add port
      @arity+=1
      super(port)
    end
  end

  class OrNGate < NaryGate
  end

  class TimesGate < BinaryGate
    def initialize name=nil
      super(name)
      @color="red"
    end
  end

  class EqlGate < BinaryGate
  end

  class GreaterThanGate < BinaryGate
  end

  class LessThanGate < BinaryGate
  end

  class PlusGate < BinaryGate
  end

  class MinusGate < BinaryGate
  end

  class SllGate < BinaryGate
  end
end
