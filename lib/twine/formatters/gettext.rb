module Twine
  module Formatters
    class Gettext < Abstract
      FORMAT_NAME = 'gettext'
      EXTENSION = '.po'
      DEFAULT_FILE_NAME = 'strings.po'

      def self.can_handle_directory?(path)
        Dir.entries(path).any? { |item| /^.+\.po$/.match(item) }
      end

      def default_file_name
        return DEFAULT_FILE_NAME
      end

      def determine_language_given_path(path)
        path_arr = path.split(File::SEPARATOR)
        path_arr.each do |segment|
          match = /(..)\.po$/.match(segment)
          if match
            return match[1]
          end
        end

        return
      end

      def read_file(path, lang)
        comment_regex = /#.? *"(.*)"$/
        key_regex = /msgctxt *"(.*)"$/
        value_regex = /msgstr *"(.*)"$/m
        File.open(path, 'r:UTF-8') do |f|
          while item = f.gets("\n\n")
            key = nil
            value = nil
            comment = nil

            for line in item.split(/\r?\n/)
              comment_match = comment_regex.match(line)
              if comment_match
                comment = comment_match[1]
              end
              key_match = key_regex.match(line)
              if key_match
                key = key_match[1].gsub('\\"', '"')
              end
              value_match = value_regex.match(line)
              if value_match
                value = value_match[1].gsub('\\"', '"')
              end
            end
            if key and key.length > 0 and value and value.length > 0
              set_translation_for_key(key, lang, value)
              if comment and comment.length > 0
                set_comment_for_key(key, comment)
              end
            end
          end
        end
      end

      def write_file(path, lang)
        default_lang = @strings.language_codes[0]
        encoding = @options[:output_encoding] || 'UTF-8'
        File.open(path, "w:#{encoding}") do |f|
          f.puts "msgid \"\"\nmsgstr \"\"\n\"Language: #{lang}\\n\"\n\"X-Generator: Twine #{Twine::VERSION}\\n\"\n\n"
          @strings.sections.each do |section|
            printed_section = false
            section.rows.each do |row|
              if row.matches_tags?(@options[:tags], @options[:untagged])
                basetrans = row.translated_string_for_lang(default_lang)

                if basetrans
                  key = row.key
                  key = key.gsub('"', '\\\\"')

                  comment = row.comment
                  if comment
                    comment = comment.gsub('"', '\\\\"')
                  end

                  if comment && comment.length > 0
                    f.print "#. \"#{comment}\"\n"
                  end

                  f.print "msgctxt \"#{key}\"\nmsgid \"#{basetrans}\"\n"
                  value = row.translated_string_for_lang(lang)
                  if value
                    value = value.gsub('"', '\\\\"')
                  end
                  f.print "msgstr \"#{value}\"\n\n"
                end
              end
            end
          end
        end
      end
    end
  end
end
