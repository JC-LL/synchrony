require_relative 'generic_lexer'
require_relative 'generic_parser'

module Synchrony
  class Lexer < GenericLexer
    def initialize
      super

      keyword 'require'
      keyword 'circuit'
      keyword 'input'
      keyword 'output'
      keyword 'end'
      keyword 'sig'

      keyword 'bit'
      keyword 'byte'
      keyword 'sbyte'


      keyword 'and'
      keyword 'or'
      keyword 'xor'
      keyword 'not'
      keyword 'and'

      #.............................................................
      token :comment           => /\A\#(.*)$/
      token :int               => /int\d*/
      token :uint              => /uint\d*/
      token :ident             => /[a-zA-Z]\w*/
      token :int_literal       => /(0x|0b)?[0-9]+\w*/
      token :string_literal    => /"[^"]*"/
      token :char_literal      => /'(\w+)'/
      token :decimal_literal   => /\d+(\.\d+)?(E([+-]?)\d+)?/

      token :dot2             => /\A\.\./
      token :comma             => /\A\,/
      token :colon             => /\A\:/
      token :semicolon         => /\A\;/
      token :lparen            => /\A\(/
      token :rparen            => /\A\)/
      token :lbrack            => /\A\[/
      token :rbrack            => /\A\]/
      token :lbrace            => /\A\{/
      token :rbrace            => /\A\}/
      token :qmark             => /\A\?/
      token :dollar            => /\A\$/
      token :excl              => /\A\!/

      # arith
      token :add               => /\A\+/
      token :sub               => /\A\-/
      token :mul               => /\A\*/
      token :div               => /\A\//

      token :concat            => /\A\_/

      # logical
      token :eq                => /\A\==/
      token :assign            => /\A\=/
      token :neq               => /\A\/\=/
      token :gte               => /\A\>\=/
      token :gt                => /\A\>/
      token :leq               => /\A\<\=/
      token :lt                => /\A\</


      token :ampersand         => /\A\&/

      token :dot               => /\A\./
      token :bar               => /\|/
      #............................................................
      token :newline           =>  /[\n]/
      token :space             => /[ \t\r]+/

    end #def
  end #class
end #module
