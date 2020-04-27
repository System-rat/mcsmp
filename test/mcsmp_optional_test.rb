require_relative 'test_helper'
require 'mcsmp'

class MCSMPOptionalTest < Minitest::Test
  def test_jar_download
    dir = Dir.mktmpdir('mcsmp')
    jar_path = File.join(dir, 'server.jar')
    dl_info = MCSMP::MineCraftVersion.snapshot.first.download_information
    total = 0
    threshold = 0.05
    print 'Downloading jar: |'
    dl_info.download(jar_path) do |dc|
      total += dc
      if (total.to_f / dl_info.size) >= threshold
        print '='
        $stdout.flush
        threshold += 0.05
      end
    end
    puts '| Done!'
    assert dl_info.verify_sha(jar_path)
  end
end
