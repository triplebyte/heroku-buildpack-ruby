require 'json'

class LanguagePack::Helpers::Nodebin
  def self.hardcoded_node_lts(version = nil)
    version = "10.14.0"
    {
      "number" => version,
      "url"    => "https://s3.amazonaws.com/heroku-nodebin/node/release/linux-x64/node-v#{version}-linux-x64.tar.gz"
    }
  end

  def self.hardcoded_yarn(version = nil)
    version ||= "1.3.2"
    {
      "number" => version,
      "url"    => "https://s3.amazonaws.com/heroku-nodebin/yarn/release/yarn-v#{version}.tar.gz"
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

  def self.node_lts
    version = detected_versions['node']
    hardcoded_node_lts(version)
  end

  def self.yarn
    version = detected_versions['yarn']
    hardcoded_yarn(version)
  end
end
