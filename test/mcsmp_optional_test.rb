require_relative 'test_helper'
require 'mcsmp'

class MCSMPOptionalTest < Minitest::Test
  def test_jar_download
    dir = Dir.mktmpdir('mcsmp')
    jar_path = File.join(dir, 'server.jar')
    dl_info = MCSMP::MineCraftVersion.snapshot.first.download_information
    total = 0
    dl_info.download(jar_path) do |dc|
      total += dc
      puts "Downloaded: #{(total.to_f / dl_info.size) * 100}%"
    end
    assert dl_info.verify_sha(jar_path)
  end
end
