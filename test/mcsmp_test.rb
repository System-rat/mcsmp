# frozen_string_literal: true

require_relative 'test_helper'
require 'mcsmp'

# noinspection RubyInstanceMethodNamingConvention
class McsmpTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MCSMP::VERSION
  end

  def test_connector_config_secret
    conf = MCSMP::ConnectorConfig.new
    assert conf.connection_secret.nil?
    secret = conf.generate_secret!
    assert_equal conf.connection_secret, secret
  end

  def test_server_properties
    props = MCSMP::ServerProperties.new pvp: true
    props[:hardcore] = true
    props[:rcon__port] = nil
    assert_equal true, props[:pvp]
    assert_equal true, props[:hardcore]
    assert_raises do
      MCSMP::ServerProperties.new bruh: false
    end
    assert_raises do
      MCSMP::ServerProperties.new pvp: 'nice'
    end
    assert_equal "pvp=true\nhardcore=true\nrcon.port=\n", props.to_config
  end

  def test_server_properties_config_read
    props = MCSMP::ServerProperties.from_config(
      "pvp=true\n# nice stuff\nhardcore=true\n"\
          "motd=Nice stuff boi\nmax-players=20\n"\
          "rcon.port=69\ndifficulty=\n"\
          "gamemode=survival\n"
    )
    assert_equal true, props[:pvp]
    assert_equal true, props[:hardcore]
    assert_equal 'Nice stuff boi', props[:motd]
    assert_equal 20, props[:max_players]
    assert_equal 69, props[:rcon__port]
    assert_nil props[:difficulty]
    assert_equal "survival", props[:gamemode]
  end

  def test_version_manifest
    snapshots = MCSMP::MineCraftVersion.snapshot
    s20w17a = snapshots.find do |s|
      s.version == '20w17a'
    end
    assert s20w17a
    assert s20w17a.is_snapshot
    assert_equal '20w17a', s20w17a.version
    assert_equal 'https://launcher.mojang.com/v1/objects/0b7e36b084577fb26148c6341d590ac14606db21/server.jar',
                 s20w17a.download_information.download_url
  end

  def test_server_instance
    instance = MCSMP::ServerInstance.from_latest_snapshot('Bruh')
    assert_equal 'Bruh', instance.server_name
    assert_equal MCSMP::MineCraftVersion.latest_snapshot, instance.version
    assert instance.version.download_information.download_url
  end

  def test_server_instance_existing
    instance =
      MCSMP::ServerInstance.from_existing('C:/Users/Boris/Desktop/MCServer')
    assert_equal '20w17a', instance.version.version
    assert_equal 'survival', instance.properties[:gamemode]
  end
end
