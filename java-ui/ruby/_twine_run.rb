require 'twine'

begin
    Twine::Runner.run(ARGV)
    rescue Twine::Error => e
    STDERR.puts e.message
    exit
end
