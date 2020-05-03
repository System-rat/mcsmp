require_relative 'test_helper'
require 'mcsmp'

class MCSMPOptionalTest < Minitest::Test
  def test_jar_download
    dir = Dir.mktmpdir('mcsmp')
    jar_path = File.join(dir, 'server.jar')
    dl_info = MCSMP::MineCraftVersion.snapshot.first.download_information
    print 'Downloading jar: |'
    dl_info.download(
      jar_path, &MCSMP::Util::ProgressBar.new(dl_info.size).start
    )
    puts '| Done!'
    assert dl_info.verify_sha(jar_path)
  end

  def test_create_server
    tmp_dir = Dir.mktmpdir('mcspm-instance-test')
    server = MCSMP::ServerInstance.from_version(
      MCSMP::MineCraftVersion.latest_snapshot,
      'BruhServer'
    )
    server.create_at_path(tmp_dir)
    assert server.exists?
    assert_path_exists server.physical_path
    assert_path_exists File.join(server.physical_path, 'server.jar')
  end
end
