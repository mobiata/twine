module Twine
  module Formatters
    class JQuery < Abstract
      FORMAT_NAME = 'jquery'
      EXTENSION = '.json'
      DEFAULT_FILE_NAME = 'localize.json'

      def self.can_handle_directory?(path)
        Dir.entries(path).any? { |item| /^.+\.json$/.match(item) }
      end

      def default_file_name
        return DEFAULT_FILE_NAME
      end

      def determine_language_given_path(path)
        path_arr = path.split(File::SEPARATOR)
        path_arr.each do |segment|
          match = /^((.+)-)?([^-]+)\.json$/.match(segment)
          if match
            return match[3]
          end
        end

        return
      end

      def read_file(path, lang)
        begin
          require "json"
        rescue LoadError
          raise Twine::Error.new "You must run 'gem install json' in order to read or write jquery-localize files."
        end

        open(path) do |io|
          json = JSON.load(io)
          json.each do |key, value|
            set_translation_for_key(key, lang, value)
          end
        end
      end

      def write_file(path, lang)
        begin
          require "json"
        rescue LoadError
          raise Twine::Error.new "You must run 'gem install json' in order to read or write jquery-localize files."
        end

        default_lang = @strings.language_codes[0]
        encoding = @options[:output_encoding] || 'UTF-8'
        File.open(path, "w:#{encoding}") do |f|
          f.puts "{"

          @strings.sections.each_with_index do |section, si|
            section.rows.each_with_index do |row, ri|
              if row.matches_tags?(@options[:tags], @options[:untagged])
                key = row.key
                key = key.gsub('"', '\\\\"')

                value = row.translated_string_for_lang(lang, default_lang)
                value = value.gsub('"', '\\\\"')

                f.print "\"#{key}\":\"#{value}\","
                f.print "\n"
              end
            end
          end
          f.seek(-2, IO::SEEK_CUR)
          f.puts "\n}"

        end
      end
    end
  end
end
