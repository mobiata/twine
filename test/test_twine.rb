require 'twine_test_case'

class TestOutputProcessor < TwineTestCase
  def setup
    super

    @strings = build_twine_file 'en' do
      add_section 'Section 1' do
        add_row key1: 'value1', tags: ['tag1']
        add_row key2: 'value2', tags: ['tag1', 'tag2']
        add_row key3: 'value3', tags: ['tag2']
        add_row key4: 'value4'
      end
    end
  end

  def test_includes_all_tags_by_default
    processor = Twine::Processors::OutputProcessor.new(@strings, {})
    result = processor.process('en')

    assert_equal result.strings_map.keys.sort, %w(key1 key2 key3 key4)
  end

  def test_filter_by_tag
    processor = Twine::Processors::OutputProcessor.new(@strings, { tags: ['tag1'] })
    result = processor.process('en')

    assert_equal result.strings_map.keys.sort, %w(key1 key2)
  end

  def test_filter_by_multiple_tags
    processor = Twine::Processors::OutputProcessor.new(@strings, { tags: ['tag1', 'tag2'] })
    result = processor.process('en')

    assert_equal result.strings_map.keys.sort, %w(key1 key2 key3)
  end

  def test_filter_untagged
    processor = Twine::Processors::OutputProcessor.new(@strings, { tags: ['tag1'], untagged: true })
    result = processor.process('en')

    assert_equal result.strings_map.keys.sort, %w(key1 key2 key4)
  end
end

class TestTwine < TwineTestCase

  def test_generate_string_file_2
    Dir.mktmpdir do |dir|
      # Aspects:
      #  - Apple formatter
      #  - Tags
      output_path = File.join(dir, 'en.strings')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-2.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_3
    Dir.mktmpdir do |dir|
      # jQuery formatter recognition
      # jQuery formatter
      output_path = File.join(dir, 'en.json')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-5.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_4
    Dir.mktmpdir do |dir|
      # key with space
      # value with space
      output_path = File.join(dir, 'en.strings')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-2.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-6.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_5
    Dir.mktmpdir do |dir|
      # Django formatter recognition
      # Django formatter
      output_path = File.join(dir, 'en.po')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-7.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_6
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.xml')
      # parametrized string
      # percentage string
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-3.txt #{output_path}))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-8.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_7
    Dir.mktmpdir do |dir|
      # android space escaping
      output_path = File.join(dir, 'en.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-2.txt #{output_path} -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-10.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_8
    Dir.mktmpdir do |dir|
      # tizen formatter
      output_path = File.join(dir, 'fr.xml')
      Twine::Runner.run(%W(generate-string-file --format tizen test/fixtures/strings-1.txt #{output_path}))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-12.txt')).result, File.read(output_path))
    end
  end

  def test_include_translated
    Dir.mktmpdir do |dir|
      # output processor: include translated
      output_path = File.join(dir, 'fr.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} --include translated))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-13.txt')).result, File.read(output_path))
    end
  end

  def test_consume_string_file_1
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      # TODO: think about consume option handling/tests
        # maybe: manually feed translations to Abstract formatter

      # android, apple, django, ... consumption

      # consume updates existing translations
      # consume leaves other translations untouched -> add_row key3: { en: 'key3-english', fr: 'key3-french' }
      # consume deducts language
      # consume deducts format (android, apple)

      # consume does not add new translations
      # consume adds new translations when -a is specified
      # updates does not update comments
      # updates comments when -c is used

      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/fr-1.xml -o #{output_path} -l fr))
      assert_equal(File.read('test/fixtures/test-output-3.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_2
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-1.strings -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-4.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_3
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-1.json -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-4.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_4
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-1.po -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-4.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_5
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-1.txt test/fixtures/en-2.po -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-9.txt'), File.read(output_path))
    end
  end

  def test_consume_string_file_6
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/strings-2.txt test/fixtures/en-3.xml -o #{output_path} -l en -a))
      assert_equal(File.read('test/fixtures/test-output-11.txt'), File.read(output_path))
    end
  end

  def test_json_line_breaks_consume
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'strings.txt')
      Twine::Runner.run(%W(consume-string-file test/fixtures/test-json-line-breaks/line-breaks.txt test/fixtures/test-json-line-breaks/line-breaks.json -l fr -o #{output_path}))
      assert_equal(File.read('test/fixtures/test-json-line-breaks/consumed.txt'), File.read(output_path))
    end
  end

  def test_json_line_breaks_generate
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'en.json')
      Twine::Runner.run(%W(generate-string-file test/fixtures/test-json-line-breaks/line-breaks.txt #{output_path}))
      assert_equal(File.read('test/fixtures/test-json-line-breaks/generated.json'), File.read(output_path))
    end
  end

  def test_generate_string_file_14_include_untranslated
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'include_untranslated.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-1.txt #{output_path} --include untranslated -l fr))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-14.txt')).result, File.read(output_path))
    end
  end

  def test_generate_string_file_14_references
    Dir.mktmpdir do |dir|
      output_path = File.join(dir, 'references.xml')
      Twine::Runner.run(%W(generate-string-file test/fixtures/strings-4-references.txt #{output_path} -l fr -t tag1))
      assert_equal(ERB.new(File.read('test/fixtures/test-output-14-references.txt')).result, File.read(output_path))
    end
  end  
end
