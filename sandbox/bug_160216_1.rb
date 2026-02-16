require "gtk3"
require 'gtksourceview3'

class Editor
  def initialize
    setup_ui
  end

  def setup_ui
    @window = Gtk::Window.new(:toplevel)
    @window.set_title("Editor")
    @window.set_default_size(1200, 800)
    @window.signal_connect("destroy") { Gtk.main_quit }
    @window.show_all
  end

  def run
    Gtk.main
  end
end

editor=Editor.new
editor.run
