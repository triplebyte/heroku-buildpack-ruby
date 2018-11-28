require 'json'
require "language_pack/shell_helpers"

class LanguagePack::Helpers::Nodebin

  URL = "https://nodebin.herokai.com/v1/"

  def self.query(q)
    response = Net::HTTP.get_response(URI("#{URL}/#{q}"))
    if response.code == '200'
      JSON.parse(response.body)
    end
  end

  def self.hardcoded_node_lts(version = nil)
    version ||= '10.14.0'
    {
      "number" => version,
      "url"    => "https://nodejs.org/dist/v#{version}/node-v#{version}-linux-x64.tar.gz"
    }
  end

  def self.hardcoded_yarn(version = nil)
    version ||= '1.12.3'
    {
      "number" => version,
      "url"    => "https://s3.amazonaws.com/heroku-nodejs-bins/yarn/release/yarn-v#{version}.tar.gz"
    }
  end

  def self.detected_versions
    return @detected_versions if defined? @detected_versions

    @detected_versions = {}
    if File.exists? 'package.json'
      package = JSON.parse(File.read('package.json'))
      engines = package['engines']
      @detected_versions.merge!(engines) if !engines.empty?
    end
    @detected_versions
  end

  def self.node(q)
    query("node/linux-x64/#{q}")
  end

  def self.node_lts
    version = detected_versions['node']
    hardcoded_node_lts(version) # node("latest?range=6.x")
  end

  def self.yarn(q)
    version = detected_versions['yarn']
    hardcoded_yarn(version) # query("yarn/linux-x64/#{q}")
  end
end
