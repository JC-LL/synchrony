module Synchrony
  # boolean_simplifier operates ONLY on Nary nodes.
  class NaryTransformer < Transformer

    def transform ast
      begin
        ast.accept(self)
      rescue Exception => e
        puts e
        puts e.backtrace
      end
    end

    BOOLEAN_OPS=[:and,:or,:xor,:nor,:nand]

    def visitBinary bin,args=nil
      #puts "visitBinary : #{bin.str}"
      ret=bin # default
      op=bin.op
      return ret unless BOOLEAN_OPS.include?(op)
      lhs=bin.lhs.accept(self)
      rhs=bin.rhs.accept(self)
      exprs=[]
      case lhs
      when Binary,Nary
        if lhs.op==op
          exprs << lhs.exprs
        else
          exprs << lhs
        end
      when Parenth
        if lhs.expr.respond_to?(:exprs) and lhs.expr.op==op
          exprs << lhs.expr.exprs
        else
          exprs << lhs
        end
      else
        exprs << lhs
      end

      case rhs
      when Binary,Nary
        if rhs.op==op
          exprs << rhs.exprs
        else
          exprs << rhs
        end
      when Parenth
        if rhs.expr.respond_to?(:exprs) and rhs.expr.op==op
          exprs << rhs.expr.exprs
        else
          exprs << rhs
        end
      else
        exprs << rhs
      end
      exprs.flatten!
      ret=Nary.new(op,exprs)
    end
  end
end
