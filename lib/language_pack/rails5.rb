require 'securerandom'
require "language_pack"
require "language_pack/rails42"

class LanguagePack::Rails5 < LanguagePack::Rails42
  # @return [Boolean] true if it's a Rails 5.x app
  def self.use?
    instrument "rails5.use" do
      rails_version = bundler.gem_version('railties')
      return false unless rails_version
      is_rails = rails_version >= Gem::Version.new('5.x') &&
                 rails_version <  Gem::Version.new('6.0.0')
      return is_rails
    end
  end

  def setup_profiled
    instrument 'setup_profiled' do
      super
      set_env_default "RAILS_LOG_TO_STDOUT", "enabled"
    end
  end

  def default_config_vars
    super.merge({
      "RAILS_LOG_TO_STDOUT" => "enabled"
    })
  end

  def webpacker_assets_folder
    "public/packs"
  end

  def webpacker_assets_cache
    "tmp/cache/webpacker"
  end

  def webpacker_bundles
    "node_modules"
  end

  def install_plugins
    # do not install plugins, do not call super, do not warn
  end

  def load_assets_cache
    super
    @cache.load_without_overwrite webpacker_assets_folder
    @cache.load webpacker_assets_cache
    @cache.load_without_overwrite webpacker_bundles
  end

  def save_assets_cache
    super
    @cache.store webpacker_bundles
    @cache.store webpacker_assets_folder
    @cache.store webpacker_assets_cache
  end

  def cleanup_assets_cache
    instrument "rails5.cleanup_assets_cache" do
      LanguagePack::Helpers::StaleFileCleaner.new(webpacker_assets_cache).clean_over(ASSETS_CACHE_LIMIT)
      LanguagePack::Helpers::StaleFileCleaner.new(default_assets_cache).clean_over(ASSETS_CACHE_LIMIT)
    end
  end
end
