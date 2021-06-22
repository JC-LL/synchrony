require "optparse"

require_relative "compiler"

module Synchrony

  class Runner

    def self.run *arguments
      new.run(arguments)
    end

    def run arguments
      compiler=Compiler.new
      compiler.options = args = parse_options(arguments)
      begin
        if filename=args[:file]
          ok=compiler.compile(filename)
        else
          raise "need a synchrony file : synchrony [options] <file>"
        end
        return ok
      rescue Exception => e
        puts e unless compiler.options[:mute]
        return false
      end
    end

    def header
      puts "synchrony (#{VERSION}) - (c) JC Le Lann 2020"
    end

    private
    def parse_options(arguments)

      parser = OptionParser.new

      no_arguments=arguments.empty?

      options = {}

      parser.on("-h", "--help", "Show help message") do
        puts parser
        exit(true)
      end

      parser.on("-p", "--parse", "parse only") do
        options[:parse_only]=true
      end

      parser.on("--pp", "pretty print back source code ") do
        options[:pp] = true
      end

      parser.on("--ast", "abstract syntax tree (AST)") do
        options[:ast] = true
      end

      parser.on("--check", "elaborate and check types") do
        options[:check] = true
      end

      parser.on("--simplify", "apply basic boolean simplifications") do
        options[:simplify] = true
      end

      parser.on("--draw_ast", "draw abstract syntax tree (AST)") do
        options[:draw_ast] = true
      end

      parser.on("--dummy_transform", "dummy ast transform") do
        options[:dummy_transform] = true
      end

      parser.on("--vv", "verbose") do
        options[:verbose] = true
      end

      parser.on("--mute","mute") do
        options[:mute]=true
      end

      parser.on("-v", "--version", "Show version number") do
        puts VERSION
        exit(true)
      end

      parser.parse!(arguments)

      header unless options[:mute]

      options[:file]=arguments.shift #the remaining file

      if no_arguments
        puts parser
      end

      options
    end
  end
end
