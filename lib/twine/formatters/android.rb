# encoding: utf-8
require 'cgi'
require 'rexml/document'

module Twine
  module Formatters
    class Android < Abstract
      FORMAT_NAME = 'android'
      EXTENSION = '.xml'
      DEFAULT_FILE_NAME = 'strings.xml'
      LANG_CODES = Hash[
        'zh' => 'zh-Hans',
        'zh-rCN' => 'zh-Hans',
        'zh-rHK' => 'zh-Hant',
        'en-rGB' => 'en-UK',
        'in' => 'id',
        'nb' => 'no'
        # TODO: spanish
      ]

      def self.can_handle_directory?(path)
        Dir.entries(path).any? { |item| /^values.*$/.match(item) }
      end

      def default_file_name
        return DEFAULT_FILE_NAME
      end

      def determine_language_given_path(path)
        path_arr = path.split(File::SEPARATOR)
        path_arr.each do |segment|
          if segment == 'values'
            return @strings.language_codes[0]
          else
            match = /^values-(.*)$/.match(segment)
            if match
              lang = match[1]
              lang = LANG_CODES.fetch(lang, lang)
              lang.sub!('-r', '-')
              return lang
            end
          end
        end

        return
      end

      def set_translation_for_key(key, lang, value)
        value = CGI.unescapeHTML(value)
        value.gsub!('\\\'', '\'')
        value.gsub!('\\"', '"')
        value = iosify_substitutions(value)
        value.gsub!(/(\\u0020)*|(\\u0020)*\z/) { |spaces| ' ' * (spaces.length / 6) }
        super(key, lang, value)
      end

      def read_file(path, lang)
        resources_regex = /<resources(?:[^>]*)>(.*)<\/resources>/m
        key_regex = /<string name="(\w+)">/
        comment_regex = /<!-- (.*) -->/
        value_regex = /<string name="\w+">(.*)<\/string>/
        key = nil
        value = nil
        comment = nil

        File.open(path, 'r:UTF-8') do |f|
          content_match = resources_regex.match(f.read)
          if content_match
            for line in content_match[1].split(/\r?\n/)
              key_match = key_regex.match(line)
              if key_match
                key = key_match[1]
                value_match = value_regex.match(line)
                value = value_match ? value_match[1] : ""

                set_translation_for_key(key, lang, value)
                if comment and comment.length > 0 and !comment.start_with?("SECTION:")
                  set_comment_for_key(key, comment)
                end
                comment = nil
              end

              comment_match = comment_regex.match(line)
              if comment_match
                comment = comment_match[1]
              end
            end
          end
        end
      end

      def format_header(lang)
        "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!-- Android Strings File -->\n<!-- Generated by Twine #{Twine::VERSION} -->\n<!-- Language: #{lang} -->"
      end

      def format_sections(strings, lang)
        result = '<resources>'
        
        result += super + "\n"

        result += '</resources>'
      end

      def format_section_header(section)
        "\t<!-- SECTION: #{section.name} -->"
      end

      def format_comment(comment)
        "\t<!-- #{comment.gsub('--', '—')} -->"
      end

      def key_value_pattern
        "\t<string name=\"%{key}\">%{value}</string>"
      end

      def format_value(value)
        # TODO: this should be more sophisticated, i.e. only html escape if necessary (http://developer.android.com/guide/topics/resources/string-resource.html#FormattingAndStyling)

        value = value.dup
        # Android enforces the following rules on the values
        #  1) apostrophes and quotes must be escaped with a backslash
        value.gsub!("'", "\\\\'")
        value.gsub!('"', '\\\\"')
        #  2) HTML escape the string
        value = CGI.escapeHTML(value)
        #  3) fix substitutions (e.g. %s/%@)
        value = androidify_substitutions(value)
        #  4) replace beginning and end spaces with \0020. Otherwise Android strips them.
        value.gsub(/\A *| *\z/) { |spaces| '\u0020' * spaces.length }
      end

    end
  end
end
