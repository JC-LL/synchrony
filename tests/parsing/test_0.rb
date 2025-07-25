require_relative "../../lib/synchrony"

filename=ARGV.first

lexer=Synchrony::Lexer.new
pp lexer.lex(filename)
