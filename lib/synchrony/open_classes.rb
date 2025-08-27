class String
  def to_tok
    Synchrony::Token.new(:ident,self,[:na,:na])
  end

  def to_ident
    Synchrony::Ident.new(self.to_tok)
  end
end
