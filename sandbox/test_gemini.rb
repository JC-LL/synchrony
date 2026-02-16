require 'gtk3'
require 'gtksourceview3'

class Editor
  def initialize
    setup_ui
  end

  def setup_ui
    @window = Gtk::Window.new(:toplevel)
    @window.set_title("Mon Éditeur Ruby")
    @window.set_default_size(800, 600)
    @window.signal_connect("destroy") { Gtk.main_quit }

    # 1. Création du buffer (le contenu) avec un langage spécifique
    lang_manager = GtkSource::LanguageManager.new
    ruby_lang = lang_manager.get_language("ruby")
    @buffer = GtkSource::Buffer.new(ruby_lang)

    # 2. Création de la vue (le widget)
    @source_view = GtkSource::View.new(@buffer)
    @source_view.show_line_numbers = true
    @source_view.highlight_current_line = true
    @source_view.monospace = true # Utilise une police à chasse fixe

    # 3. On place la vue dans un ScrolledWindow pour pouvoir défiler
    scrolled_window = Gtk::ScrolledWindow.new
    scrolled_window.add(@source_view)

    @window.add(scrolled_window)
    @window.show_all
  end

  def run
    Gtk.main
  end
end

editor = Editor.new
editor.run
