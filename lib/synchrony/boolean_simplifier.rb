module Synchrony
  class BooleanSimplifier < Transformer
    def simplify ast
      begin
        ast.accept(self)
      rescue Exception => e
        puts e
        puts e.backtrace
        abort
      end
    end

    def visitNary nary,args=nil
      #puts "visitNary #{nary.str}"
      exprs=nary.exprs.map{|e| e.accept(self)}
      case nary.op
      when :or
        return IntLit.new(ONE)  if exprs.any?{|e| e.str=="1"} # existential closure.
        return IntLit.new(ZERO) if exprs.all?{|e| e.str=="0"}
        exprs.delete_if{|e| e.str=="0"}
        exprs=[exprs.first] if exprs.map(&:str).uniq.size==1  # absorption.
        return IntLit.new(ONE) if have_opposites?(exprs)
      when :and
        return IntLit.new(ZERO) if exprs.any?{|e| e.str=="0"} # universal closure.
        return IntLit.new(ONE)  if exprs.all?{|e| e.str=="1"}
        exprs.delete_if{|e| e.str=="1"}
        exprs=[exprs.first] if exprs.map(&:str).uniq.size==1
        return IntLit.new(ZERO) if have_opposites?(exprs)
      end
      Nary.new(nary.op,exprs)
    end

    def have_opposites? exprs
      puts "have_opposites? #{exprs.map(&:str)}"
      strs=exprs.map(&:str)
      not_strs=strs.map{|e| "!#{e}"}
      not_strs.each do |ne|
        return true if strs.include?(ne)
      end
      false
    end

    def visitUnary unary,args=nil
      puts "visitUnary #{unary.str}"
      expr=Unary.new(unary.op,unary.expr.accept(self))
      expr=apply_not_not(expr)
      expr=apply_not_x(expr,1)
      expr=apply_not_x(expr,0)
      expr
    end

    def visitReg reg,args=nil
      reg_expr=reg.expr.accept(self)
      if (e=reg_expr).is_a? Lit
        return e
      end
      reg
    end

    def apply_not_not unary
      if unary.op==:not
        if unary.expr.is_a?(Unary) and unary.expr.op=:not
          return unary.expr.expr
        end
      end
      return unary
    end

    def apply_not_x expr,x=1
      return expr unless expr.is_a?(Unary)
      ret=expr
      cst=x==1 ? ZERO : ONE
      if expr.op==:not
        case parenth=expr.expr
        when IntLit
          if expr.expr.to_i==x
            ret=IntLit.new(cst)
          end
        when Parenth
          if parenth.expr.str=="#{x}"
            ret=IntLit.new(cst)
          end
        end
      end
      ret
    end

    def visitParenth par,args=nil
      expr=par.expr.accept(self)
      case expr
      when IntLit,Ident,Unary,Parenth
        return expr
      else
        puts "returning (#{expr.str})"
        return Parenth.new(expr)
      end
    end
  end
end
