require_relative './lib/synchrony/version'

Gem::Specification.new do |s|
  s.name        = 'synchrony'
  s.version     = RTL::VERSION
  s.date        = Time.now.strftime('%F')
  s.summary     = "simple hardware description language"
  s.description = "simple digital circuit modeling, with hierarchy and graphviz output"
  s.authors     = ["Jean-Christophe Le Lann"]
  s.email       = 'jean-christophe.le_lann@ensta-bretagne.fr'
  s.files       = [
                   "lib/synchrony/ast.rb",
                   "lib/synchrony/code.rb",
                   "lib/synchrony/compiler.rb",
                   "lib/synchrony/elaborator.rb",
                   "lib/synchrony/generic_lexer.rb",
                   "lib/synchrony/generic_parser.rb",
                   "lib/synchrony/lexer.rb",
                   "lib/synchrony/parser.rb",
                   "lib/synchrony/pretty_printer.rb",
                   "lib/synchrony/runner.rb",
                   "lib/synchrony/token.rb",
                   "lib/synchrony/transformer.rb",
                   "lib/synchrony/version.rb",
                   "lib/synchrony/visitor.rb",
                   "lib/synchrony.rb"
                  ]
  s.files += Dir["tests/*/*.syc"]
  s.homepage    = 'http://www.github.com/JC-LL/synchrony'
  s.license       = 'GPL-2.0-only'
  s.add_runtime_dependency 'rtl_circuit', '>= 0.6'
end
