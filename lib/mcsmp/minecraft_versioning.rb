# frozen_string_literal: true

require 'net/http'
require 'json'

module MCSMP
  # Holds methods for retrieving MineCraft versions
  module MineCraftVersion
    # Represents download information for a server.jar
    class MCServerDownloadInfo
      attr_accessor :download_url, :size, :sha1

      def initialize(d_url, size, sha1)
        @download_url = d_url
        @size = size
        @sha1 = sha1
      end

      def download(target_file)
        request_url = URI(@download_url)
        Net::HTTP.start(
          request_url.host,
          request_url.port,
          use_ssl: true
        ) do |http|
          get_request = Net::HTTP::Get.new request_url
          http.request(get_request) do |response|
            begin
              file = File.open(target_file, 'wb')
              response.read_body do |chunk|
                count = file.write(chunk)
                yield count if block_given?
              end
            ensure
              file.close
            end
          end
        end
      end

      def verify_sha(target_file)
        @sha1 == Digest::SHA1.hexdigest(File.open(target_file, 'rb').read)
      end
    end

    # Holds information on a MineCraft version
    class MCVersion
      attr_accessor :version, :is_snapshot, :detailed_manifest_url

      def initialize(version, is_snapshot, dm_url)
        @version = version
        @is_snapshot = is_snapshot
        @detailed_manifest_url = dm_url
      end

      def download_information
        @download_information ||=
          begin
            data = JSON.parse(
              Net::HTTP.get(URI(@detailed_manifest_url))
            ).dig('downloads', 'server')
            MineCraftVersion::MCServerDownloadInfo.new(
              data['url'], data['size'].to_i, data['sha1']
            )
          end
      end

      def ==(other)
        return false unless other.is_a? MCVersion

        (@version == other.version) &&
          (@is_snapshot == other.is_snapshot) &&
          (@detailed_manifest_url == other.detailed_manifest_url)
      end
    end

    VERSION_MANIFEST_URL = URI('https://launchermeta.mojang.com/mc/game/version_manifest.json')

    module_function

    def manifest
      @manifest ||= begin
                      data = Net::HTTP.get(VERSION_MANIFEST_URL)
                      JSON.parse(data)
                    end
    end

    def stable
      @stable ||=
        manifest['versions']
        .select { |e| e['type'] == 'release' }
        .map do |snap|
          MCVersion.new(snap['id'], false, snap['url'])
        end
    end

    def snapshot
      @snapshot ||=
        manifest['versions']
        .select { |e| e['type'] == 'snapshot' }
        .map do |snap|
          MCVersion.new(snap['id'], true, snap['url'])
        end
    end

    def latest_snapshot
      latest(:snapshot)
    end

    def latest_release
      latest(:release)
    end

    def invalidate_manifest_cache
      @snapshot = nil
      @stable = nil
      @manifest = nil
    end

    def specific_version(version_name)
      version = stable.find do |v|
        v.version == version_name
      end
      version ||= snapshot.find do |v|
        v.version == version_name
      end
      raise ArgumentError, "Version does not exist: #{version_name}" unless version

      version
    end

    class << self
      private

      def latest(type)
        version = if type == :snapshot
                    manifest['versions'].first
                  else
                    manifest['versions'].find { |v| v['id'] == manifest['latest']['release'] }
                  end
        MCVersion.new(version['id'], type == :snapshot, version['url'])
      end
    end

  end
end

