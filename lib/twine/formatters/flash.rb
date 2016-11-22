module Twine
  module Formatters
    class Flash < Abstract
      include Twine::Placeholders

      def format_name
        'flash'
      end

      def extension
        '.properties'
      end

      def can_handle_directory?(path)
        return false
      end

      def default_file_name
        'resources.properties'
      end

      def determine_language_given_path(path)
        return

      def set_translation_for_key(key, lang, value)
        value = convert_placeholders_from_android_to_twine(value)
        super(key, lang, value)
      end

      def read(io, lang)
        last_comment = nil
        while line = io.gets
          match = /((?:[^"\\]|\\.)+)\s*=\s*((?:[^"\\]|\\.)*)/.match(line)
          if match
            key = match[1]
            value = match[2].strip

            set_translation_for_key(key, lang, value)
            set_comment_for_key(key, last_comment) if last_comment
          end
          
          match = /# *(.*)/.match(line)
          last_comment = match ? match[1] : nil
        end
      end

      def format_sections(twine_file, lang)
        super + "\n"
      end

      def format_header(lang)
        "## Flash Strings File\n## Generated by Twine #{Twine::VERSION}\n## Language: #{lang}"
      end

      def format_section_header(section)
        "## #{section.name} ##\n"
      end

      def format_comment(definition, lang)
        "# #{definition.comment}\n" if definition.comment
      end

      def key_value_pattern
        "%{key}=%{value}"
      end

      def format_value(value)
        convert_placeholders_from_twine_to_flash(value)
      end
    end
  end
end

Twine::Formatters.formatters << Twine::Formatters::Flash.new
