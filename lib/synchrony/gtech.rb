module Synchrony

  class Gate1 < Circuit
    def initialize name=nil
      super(name)
      self << Input.new(:i)
      self << Output.new(:f)
    end
  end

  class Gate2 < Circuit
    def initialize name=nil
      super(name)
      self << Input.new(:i1)
      self << Input.new(:i2)
      self << Output.new(:f)
    end
  end

  class Inv < Gate1
  end

  class And2 < Gate2
  end

  class Or2 < Gate2
  end

  class Nor2 < Gate2
  end

  class Xor2 < Gate2
  end

  class Nand2 < Gate2
  end

  class CmpEq < Gate2
  end

  GTECH_GATES=[Inv,And2,Or2,Xor2,Nand2]

  #==================== RTL===================
  class Mux2 < Circuit
    def initialize name=nil
      super(name)
      self << Input.new(:i1)
      self << Input.new(:i2)
      self << Input.new(:cmd,Bit.new)
      self << Output.new(:f)
    end
  end

  class Add < Gate2
  end

  class Sub < Gate2
  end

  class Mul < Gate2
  end

  class Div < Gate2
  end

  class Mod < Gate2
  end

  class Reg < Circuit
    def initialize name=nil
      super(name)
      self << Input.new(:d)
      self << Output.new(:q)
    end
  end

  class Slicer < Circuit
    attr_accessor :range
    def initialize range,name=nil
      super(name)
      self << Input.new(:i)
      self << Output.new(:f)
    end
  end

  class Joiner < Circuit
    attr_accessor :cardinality
    def initialize cardinality,name=nil
      super(name)
      cardinality.times do |i|
        pname="i#{i}".to_sym
        self << Input.new(pname)
      end
      self << Output.new(:f)
    end
  end

  GTECH_RTL=[Reg,Add,Mux2,Add,Sub,Mul,Div,Mod,Slicer]

end
