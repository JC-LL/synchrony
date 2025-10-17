#!/usr/bin/env ruby

require 'gtk3'
require 'gtksourceview3'
require 'json'
require 'cairo'
require 'fileutils'
require 'open3'
require 'rsvg2'

class SynchronyEditor
  def initialize
    @current_file = nil
    @svg_handle = nil
    @config = load_config
    setup_ui
    setup_keyboard_shortcuts
  end

  # ... (le reste du code reste inchangé jusqu'à la méthode apply_dark_theme)
  def load_config
    config_path = File.expand_path('config.json')
    if File.exist?(config_path)
      JSON.parse(File.read(config_path))
    else
      # Configuration par défaut
      {
        "syntax_highlighting" => {
          "circuit" => "#FF6B6B",
          "end" => "#4ECDC4",
          "input" => "#FFE66D",
          "output" => "#45B7D1"
        },
        "theme" => "dark",
        "dot_path" => "dot",
        "dot_options": "-Tsvg",
        "font": {
          "family": "Monospace",
          "size": 12
        },
        "line_numbers": {
          "enabled": true,
          "margin": 10  # Nouveau paramètre pour la marge
        }
      }
    end
  end

  def setup_ui
    # Fenêtre principale
    @window = Gtk::Window.new(:toplevel)
    @window.set_title("Synchrony EDA Editor")
    @window.set_default_size(1200, 800)
    @window.signal_connect("destroy") { Gtk.main_quit }

    # Conteneur principal
    main_box = Gtk::Box.new(:vertical, 0)
    @window.add(main_box)

    # Barre de menus
    setup_menu_bar(main_box)

    # Panneau principal (split horizontal)
    main_paned = Gtk::Paned.new(:horizontal)
    main_box.pack_start(main_paned, expand: true, fill: true, padding: 0)

    # Panneau gauche (split vertical)
    left_paned = Gtk::Paned.new(:vertical)
    main_paned.add1(left_paned)

    # Zone de code avec GtkSourceView
    @code_buffer = GtkSource::Buffer.new
    setup_syntax_highlighting

    # Créer la vue avec le buffer
    @code_view = GtkSource::View.new
    @code_view.buffer = @code_buffer
    @code_view.set_show_line_numbers(@config.dig("line_numbers", "enabled") || true)
    @code_view.set_auto_indent(true)
    @code_view.set_tab_width(2)
    @code_view.set_insert_spaces_instead_of_tabs(true)
    @code_view.set_highlight_current_line(true)
    @code_view.set_wrap_mode(:word_char)

    # Ajouter une marge à gauche du code
    margin = @config.dig("line_numbers", "margin") || 10
    @code_view.set_left_margin(margin)

    apply_font_settings(@code_view)

    code_scroll = Gtk::ScrolledWindow.new
    code_scroll.set_policy(:automatic, :automatic)
    code_scroll.add(@code_view)
    left_paned.add1(code_scroll)

    # Zone de log avec scroll
    @log_view = Gtk::TextView.new
    @log_view.set_editable(false)
    @log_view.set_wrap_mode(:word_char)
    @log_buffer = @log_view.buffer
    apply_font_settings(@log_view)

    log_scroll = Gtk::ScrolledWindow.new
    log_scroll.set_policy(:automatic, :automatic)
    log_scroll.add(@log_view)
    left_paned.add2(log_scroll)

    # Zone d'affichage SVG
    @svg_area = Gtk::DrawingArea.new
    @svg_area.signal_connect("draw") { |widget, cr| draw_svg(widget, cr) }

    svg_scroll = Gtk::ScrolledWindow.new
    svg_scroll.set_policy(:automatic, :automatic)
    svg_scroll.add(@svg_area)
    main_paned.add2(svg_scroll)

    # Configuration des splitpanes
    left_paned.set_position(600)
    main_paned.set_position(800)

    # Appliquer le thème nuit
    apply_dark_theme

    @window.show_all
  end

  def setup_syntax_highlighting
    # Configurer le style de syntaxe
    style_scheme_manager = GtkSource::StyleSchemeManager.new
    # Essayer différents schémas de thème sombre
    scheme = style_scheme_manager.get_scheme("oblivion") ||
             style_scheme_manager.get_scheme("classic") ||
             style_scheme_manager.get_scheme("tango")
    @code_buffer.style_scheme = scheme if scheme

    # Appliquer la coloration syntaxique personnalisée
    tag_table = @code_buffer.tag_table

    @config["syntax_highlighting"].each do |keyword, color|
      tag_name = "keyword_#{keyword}"
      tag = Gtk::TextTag.new(tag_name)
      tag.foreground = color
      tag.weight = Pango::Weight::BOLD
      tag_table.add(tag)
    end

    @code_buffer.signal_connect("changed") do
      update_syntax_highlighting
    end
  end

  def update_syntax_highlighting
    # Supprimer les anciens tags
    start_iter = @code_buffer.get_iter_at(offset: 0)
    end_iter = @code_buffer.get_iter_at(offset: -1)
    @code_buffer.remove_all_tags(start_iter, end_iter)

    # Appliquer les nouveaux tags
    text = @code_buffer.text
    @config["syntax_highlighting"].each_key do |keyword|
      regex = /\b#{Regexp.escape(keyword)}\b/i
      offset = 0

      while match = text.match(regex, offset)
        start_iter = @code_buffer.get_iter_at(offset: match.begin(0))
        end_iter = @code_buffer.get_iter_at(offset: match.end(0))

        tag = @code_buffer.tag_table.lookup("keyword_#{keyword}")
        @code_buffer.apply_tag(tag, start_iter, end_iter) if tag

        offset = match.end(0)
      end
    end
  end

  def apply_font_settings(text_view)
    font_family = @config.dig("font", "family") || "Monospace"
    font_size = @config.dig("font", "size") || 12

    font_desc = Pango::FontDescription.new("#{font_family} #{font_size}")
    text_view.override_font(font_desc)
  end

  def setup_menu_bar(main_box)
    menu_bar = Gtk::MenuBar.new

    # Menu Fichier
    file_menu = Gtk::Menu.new
    file_item = Gtk::MenuItem.new(label: "Fichier")
    file_item.set_submenu(file_menu)

    new_item = Gtk::MenuItem.new(label: "Nouveau")
    new_item.signal_connect("activate") { new_file }
    file_menu.append(new_item)

    open_item = Gtk::MenuItem.new(label: "Ouvrir")
    open_item.signal_connect("activate") { open_file }
    file_menu.append(open_item)

    save_item = Gtk::MenuItem.new(label: "Enregistrer")
    save_item.signal_connect("activate") { save_file }
    file_menu.append(save_item)

    save_as_item = Gtk::MenuItem.new(label: "Enregistrer sous")
    save_as_item.signal_connect("activate") { save_file_as }
    file_menu.append(save_as_item)

    quit_item = Gtk::MenuItem.new(label: "Quitter")
    quit_item.signal_connect("activate") { Gtk.main_quit }
    file_menu.append(quit_item)

    menu_bar.append(file_item)

    # Menu Edition
    edit_menu = Gtk::Menu.new
    edit_item = Gtk::MenuItem.new(label: "Édition")
    edit_item.set_submenu(edit_menu)

    undo_item = Gtk::MenuItem.new(label: "Annuler")
    undo_item.signal_connect("activate") { @code_buffer.undo if @code_buffer.can_undo? }
    edit_menu.append(undo_item)

    redo_item = Gtk::MenuItem.new(label: "Refaire")
    redo_item.signal_connect("activate") { @code_buffer.redo if @code_buffer.can_redo? }
    edit_menu.append(redo_item)

    menu_bar.append(edit_item)

    # Menu Compilation
    compile_menu = Gtk::Menu.new
    compile_item = Gtk::MenuItem.new(label: "Compilation")
    compile_item.set_submenu(compile_menu)

    compile_now_item = Gtk::MenuItem.new(label: "Compiler")
    compile_now_item.signal_connect("activate") { compile_code }
    compile_menu.append(compile_now_item)

    # Commande de nettoyage du log
    clear_log_item = Gtk::MenuItem.new(label: "Nettoyer le log")
    clear_log_item.signal_connect("activate") { clear_log }
    compile_menu.append(clear_log_item)

    menu_bar.append(compile_item)

    # Menu Affichage
    view_menu = Gtk::Menu.new
    view_item = Gtk::MenuItem.new(label: "Affichage")
    view_item.set_submenu(view_menu)

    # Option pour activer/désactiver les numéros de ligne
    line_numbers_item = Gtk::CheckMenuItem.new(label: "Numéros de ligne")
    line_numbers_item.active = @config.dig("line_numbers", "enabled") != false
    line_numbers_item.signal_connect("toggled") do |item|
      @config["line_numbers"] ||= {}
      @config["line_numbers"]["enabled"] = item.active?
      @code_view.set_show_line_numbers(item.active?)
    end
    view_menu.append(line_numbers_item)

    menu_bar.append(view_item)

    main_box.pack_start(menu_bar, expand: false, fill: true, padding: 0)
  end

  def clear_log
    @log_buffer.text = ""
    timestamp = Time.now.strftime("%H:%M:%S")
    @log_buffer.text = "[#{timestamp}] Log nettoyé\n"
  end

  def setup_keyboard_shortcuts
    # Raccourci F5 pour compiler
    accel_group = Gtk::AccelGroup.new
    @window.add_accel_group(accel_group)

    compile_item = Gtk::MenuItem.new
    compile_item.signal_connect("activate") { compile_code }
    compile_item.add_accelerator("activate", accel_group,
                               Gdk::Keyval::KEY_F5,
                               0,
                               :visible)
  end

  def apply_dark_theme
    css_provider = Gtk::CssProvider.new
    css = <<-CSS
      /* Style pour la barre de menus */
      menubar {
        background-color: #1A202C;
        color: #E2E8F0;
        border-bottom: 1px solid #4A5568;
      }

      menubar > menuitem {
        background-color: #1A202C;
        color: #E2E8F0;
        padding: 8px 12px;
      }

      menubar > menuitem:hover {
        background-color: #2D3748;
      }

      /* Style pour les panneaux principaux */
      * {
        background-color: #2D3748;
        color: #E2E8F0;
      }

      /* Style pour les conteneurs de scroll */
      scrolledwindow {
        background-color: #2D3748;
      }

      scrolledwindow viewport {
        background-color: #2D3748;
      }

      /* Style pour les zones de texte */
      textview {
        background-color: #1A202C;
        color: #E2E8F0;
        font-family: 'Monospace';
        font-size: 12px;
      }

      /* Style pour GtkSourceView */
      .gtksourceview {
        background-color: #1A202C;
        color: #E2E8F0;
        font-family: 'Monospace';
        font-size: 12px;
      }

      /* Style pour les numéros de ligne */
      .gtksourceview gutter {
        background-color: #2D3748;
        border-right: 1px solid #4A5568;
      }

      .gtksourceview gutter:backdrop {
        background-color: #2D3748;
      }

      /* Style pour les barres de défilement */
      scrollbar {
        background-color: #4A5568;
      }

      scrollbar slider {
        background-color: #718096;
      }

      scrollbar trough {
        background-color: #2D3748;
      }

      /* Style pour les zones de dessin (SVG) */
      drawingarea {
        background-color: #2D3748;
      }

      /* Style pour les panneaux split */
      paned {
        background-color: #2D3748;
      }

      paned separator {
        background-color: #4A5568;
        border: none;
      }

      /* Style pour les menus déroulants */
      menu {
        background-color: #1A202C;
        color: #E2E8F0;
        border: 1px solid #4A5568;
      }

      menu > menuitem {
        background-color: #1A202C;
        color: #E2E8F0;
        padding: 8px 12px;
      }

      menu > menuitem:hover {
        background-color: #2D3748;
      }
    CSS

    css_provider.load_from_data(css)
    Gtk::StyleContext.add_provider_for_screen(
      Gdk::Screen.default,
      css_provider,
      Gtk::StyleProvider::PRIORITY_APPLICATION
    )
  end

  # ... (le reste du code reste inchangé jusqu'à la méthode draw_svg)
  def new_file
    @current_file = nil
    @code_buffer.text = ""
    @svg_handle = nil
    @svg_area.queue_draw
    clear_log
    @window.set_title("Synchrony EDA Editor - Nouveau fichier")
  end

  def open_file
    dialog = Gtk::FileChooserDialog.new(
      title: "Ouvrir un fichier .syc",
      action: :open,
      buttons: [
        ["Annuler", :cancel],
        ["Ouvrir", :accept]
      ]
    )

    filter = Gtk::FileFilter.new
    filter.name = "Fichiers Synchrony (*.syc)"
    filter.add_pattern("*.syc")
    dialog.add_filter(filter)

    if dialog.run == :accept
      @current_file = dialog.filename
      @code_buffer.text = File.read(@current_file)
      @window.set_title("Synchrony EDA Editor - #{File.basename(@current_file)}")

      clear_log

      # Essayer de charger le SVG correspondant s'il existe
      svg_file = @current_file.sub('.syc', '.svg')
      load_svg_file(svg_file) if File.exist?(svg_file)
    end

    dialog.destroy
  end

  def save_file
    if @current_file
      File.write(@current_file, @code_buffer.text)
    else
      save_file_as
    end
  end

  def save_file_as
    dialog = Gtk::FileChooserDialog.new(
      title: "Enregistrer le fichier",
      action: :save,
      buttons: [
        ["Annuler", :cancel],
        ["Enregistrer", :accept]
      ]
    )

    filter = Gtk::FileFilter.new
    filter.name = "Fichiers Synchrony (*.syc)"
    filter.add_pattern("*.syc")
    dialog.add_filter(filter)

    if dialog.run == :accept
      filename = dialog.filename
      unless filename.end_with?('.syc')
        filename += '.syc'
      end

      @current_file = filename
      File.write(@current_file, @code_buffer.text)
      @window.set_title("Synchrony EDA Editor - #{File.basename(@current_file)}")
    end

    dialog.destroy
  end

  def load_svg_file(svg_file)
    begin
      if File.exist?(svg_file)
        @svg_handle = RSVG::Handle.new_from_file(svg_file)
        @svg_file = svg_file
        @svg_area.queue_draw
        true
      else
        @svg_handle = nil
        @svg_file = nil
        false
      end
    rescue => e
      @log_buffer.text += "\nErreur lors du chargement du SVG: #{e.message}"
      @svg_handle = nil
      false
    end
  end

  def compile_code
    return unless @current_file && File.exist?(@current_file)

    timestamp = Time.now.strftime("%H:%M:%S")
    @log_buffer.text = "[#{timestamp}] Compilation en cours...\n"

    save_file

    Thread.new do
      begin
        sync_command = "synchrony \"#{@current_file}\""
        stdout, stderr, status = Open3.capture3(sync_command)

        GLib::Idle.add do
          timestamp = Time.now.strftime("%H:%M:%S")
          log_content = "[#{timestamp}] Compilation synchrony terminée\n"
          log_content += "Commande: #{sync_command}\n"
          log_content += "Status: #{status.success? ? 'SUCCÈS' : 'ÉCHEC'}\n\n"

          if stdout && !stdout.empty?
            log_content += "=== STDOUT ===\n#{stdout}\n"
          end

          if stderr && !stderr.empty?
            log_content += "=== STDERR ===\n#{stderr}\n"
          end

          @log_buffer.text = log_content

          if status.success?
            generate_svg_from_dot
          else
            @log_buffer.text += "\n[#{timestamp}] Arrêt: impossible de générer SVG suite à l'échec de la compilation"
          end

          false
        end

      rescue Errno::ENOENT => e
        GLib::Idle.add do
          timestamp = Time.now.strftime("%H:%M:%S")
          @log_buffer.text = "[#{timestamp}] ERREUR: Compilateur 'synchrony' introuvable!\n"
          @log_buffer.text += "Assurez-vous que le compilateur est dans votre PATH.\n"
          @log_buffer.text += "Détail: #{e.message}"
          false
        end
      rescue => e
        GLib::Idle.add do
          timestamp = Time.now.strftime("%H:%M:%S")
          @log_buffer.text = "[#{timestamp}] ERREUR inattendue lors de la compilation!\n"
          @log_buffer.text += "Détail: #{e.message}\n"
          @log_buffer.text += "Backtrace:\n#{e.backtrace.join("\n")}"
          false
        end
      end
    end
  end

  def generate_svg_from_dot
    Thread.new do
      begin
        dot_file = @current_file.sub('.syc', '.dot')
        svg_file = @current_file.sub('.syc', '.svg')

        unless File.exist?(dot_file)
          GLib::Idle.add do
            timestamp = Time.now.strftime("%H:%M:%S")
            @log_buffer.text += "\n[#{timestamp}] ERREUR: Fichier .dot non trouvé: #{dot_file}"
            false
          end
          return
        end

        dot_path = @config["dot_path"] || "dot"
        dot_options = @config["dot_options"] || "-Tsvg"
        dot_command = "#{dot_path} #{dot_options} \"#{dot_file}\" -o \"#{svg_file}\""

        stdout, stderr, status = Open3.capture3(dot_command)

        GLib::Idle.add do
          timestamp = Time.now.strftime("%H:%M:%S")

          if status.success?
            @log_buffer.text += "\n[#{timestamp}] SVG généré avec succès!\n"
            @log_buffer.text += "Commande dot: #{dot_command}\n"

            if stdout && !stdout.empty?
              @log_buffer.text += "=== DOT STDOUT ===\n#{stdout}\n"
            end

            if stderr && !stderr.empty?
              @log_buffer.text += "=== DOT STDERR ===\n#{stderr}\n"
            end

            if load_svg_file(svg_file)
              @log_buffer.text += "\n[#{timestamp}] SVG chargé: #{File.basename(svg_file)}"
            else
              @log_buffer.text += "\n[#{timestamp}] ERREUR: Impossible de charger le SVG généré"
            end
          else
            @log_buffer.text += "\n[#{timestamp}] ERREUR lors de la génération SVG!\n"
            @log_buffer.text += "Commande dot: #{dot_command}\n"
            @log_buffer.text += "Code d'erreur: #{status.exitstatus}\n"

            if stderr && !stderr.empty?
              @log_buffer.text += "=== ERREURS DOT ===\n#{stderr}\n"
            end

            if stdout && !stdout.empty?
              @log_buffer.text += "=== SORTIE DOT ===\n#{stdout}\n"
            end
          end

          false
        end

      rescue Errno::ENOENT => e
        GLib::Idle.add do
          timestamp = Time.now.strftime("%H:%M:%S")
          @log_buffer.text += "\n[#{timestamp}] ERREUR: Commande 'dot' introuvable!\n"
          @log_buffer.text += "Assurez-vous que Graphviz est installé et dans votre PATH.\n"
          @log_buffer.text += "Détail: #{e.message}"
          false
        end
      rescue => e
        GLib::Idle.add do
          timestamp = Time.now.strftime("%H:%M:%S")
          @log_buffer.text += "\n[#{timestamp}] ERREUR inattendue lors de la génération SVG!\n"
          @log_buffer.text += "Détail: #{e.message}\n"
          @log_buffer.text += "Backtrace:\n#{e.backtrace.join("\n")}"
          false
        end
      end
    end
  end

  def draw_svg(widget, cr)
    width = widget.allocated_width
    height = widget.allocated_height

    # Fond avec la même couleur que le thème
    cr.set_source_rgb(*hex_to_rgb("#2D3748"))
    cr.rectangle(0, 0, width, height)
    cr.fill

    if @svg_handle
      render_svg(cr, width, height)
    else
      # Message si aucun SVG n'est chargé (avec la couleur du thème)
      cr.set_source_rgb(*hex_to_rgb("#E2E8F0"))
      cr.select_font_face("Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
      cr.set_font_size(14)

      text = @svg_file ? "SVG: #{File.basename(@svg_file)} (erreur de chargement)" : "Aucun SVG chargé"
      extents = cr.text_extents(text)
      x = (width - extents.width) / 2
      y = (height - extents.height) / 2

      cr.move_to(x, y)
      cr.show_text(text)

      if @svg_file && File.exist?(@svg_file)
        file_info = "Taille: #{File.size(@svg_file)} bytes"
        cr.set_font_size(10)
        cr.move_to(x, y + 20)
        cr.show_text(file_info)
      end
    end
  end

  def hex_to_rgb(hex_color)
    hex_color = hex_color.gsub('#', '')
    r = hex_color[0..1].to_i(16) / 255.0
    g = hex_color[2..3].to_i(16) / 255.0
    b = hex_color[4..5].to_i(16) / 255.0
    [r, g, b]
  end

  def render_svg(cr, width, height)
    begin
      svg_width = @svg_handle.width
      svg_height = @svg_handle.height

      scale_x = width.to_f / svg_width
      scale_y = height.to_f / svg_height
      scale = [scale_x, scale_y].min

      x_offset = (width - (svg_width * scale)) / 2
      y_offset = (height - (svg_height * scale)) / 2

      # Dessiner un fond derrière le SVG pour les marges
      cr.set_source_rgb(*hex_to_rgb("#2D3748"))
      cr.rectangle(0, 0, width, height)
      cr.fill

      # Appliquer la transformation
      cr.save
      cr.translate(x_offset, y_offset)
      cr.scale(scale, scale)

      # Rendre le SVG
      @svg_handle.render_cairo(cr)

      cr.restore

    rescue => e
      # En cas d'erreur de rendu
      cr.set_source_rgb(*hex_to_rgb("#E2E8F0"))
      cr.select_font_face("Sans", Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)
      cr.set_font_size(12)
      cr.move_to(10, 20)
      cr.show_text("Erreur de rendu SVG: #{e.message}")
    end
  end

  def run
    Gtk.main
  end
end

# Lancement de l'application
if __FILE__ == $0
  editor = SynchronyEditor.new
  editor.run
end
