require_relative '../spec_helper'

describe "Ruby apps" do
  describe "vendoring libpq" do
    it "works on heroku-16" do
      skip "Blocked on getting heroku-16 docker example to work https://github.com/schneems/libpq_heroku_16_reproduction/tree/schneems/manually-download-install"

      Hatchet::Runner.new("libpq_connection_error", stack: "heroku-16").deploy do |app|
        out = app.run("ruby reproduce_error.rb")
        expect(out).to match(%Q{invalid integer value "15s"})
      end
    end

    it "works on heroku-18" do
      Hatchet::Runner.new("libpq_connection_error", stack: "heroku-18").deploy do |app|
        out = app.run("ruby reproduce_error.rb")
        expect(out).to match(%Q{invalid integer value "15s"})
      end
    end
  end

  describe "running Ruby from outside the default dir" do
    it "works" do
      Hatchet::Runner.new('cd_ruby', stack: DEFAULT_STACK).deploy do |app|
        expect(app.output).to match("cd version ruby 2.5.1")
      end
    end
  end

  describe "bundler ruby version matcher" do
    it "installs a version even when not present in the Gemfile.lock" do
      Hatchet::Runner.new('bundle-ruby-version-not-in-lockfile', stack: DEFAULT_STACK).deploy do |app|
        expect(app.output).to         match("2.5.1")
        expect(app.run("ruby -v")).to match("2.5.1")
      end
    end

    it "works even when patchfile is specified" do
      Hatchet::Runner.new('problem_gemfile_version', stack: DEFAULT_STACK).deploy do |app|
        expect(app.output).to match("2.5.1")
      end
    end
  end

  describe "2.5.0" do
    it "works" do
      Hatchet::Runner.new("ruby_25").deploy do |app|
        expect(app.output).to include("There is a more recent Ruby version available")
      end
    end
  end

  # describe "default WEB_CONCURRENCY" do
  #   it "auto scales WEB_CONCURRENCY" do
  #     pending("https://github.com/heroku/api/issues/4426")
  #     app = Hatchet::Runner.new("default_ruby")
  #     app.setup!
  #     app.set_config("SENSIBLE_DEFAULTS" => "enabled")
  #     app.deploy do |app|
  #       app.run('echo "loaded"')
  #       expect(app.run(:bash, 'echo "value: $WEB_CONCURRENCY"', heroku: { size: "1X" } )).to match("value: 2")
  #       expect(app.run(:bash, 'echo "value: $WEB_CONCURRENCY"', heroku: { size: "2X" } )).to match("value: 4")
  #       expect(app.run(:bash, 'echo "value: $WEB_CONCURRENCY"', heroku: { size: "PX" } )).to match("value: 16")
  #     end
  #   end
  # end

  describe "Rake detection" do
    context "default" do
      # it "adds default process types" do
      #   Hatchet::Runner.new('empty-procfile').deploy do |app|
      #     app.run("console") do |console|
      #       console.run("puts 'hello' + 'world'") {|result| expect(result).to match('helloworld')}
      #     end
      #   end
      # end
    end

    context "Ruby 1.9+" do
      it "runs a rake task if the gem exists" do
        Hatchet::Runner.new('default_with_rakefile').deploy do |app, heroku|
          expect(app.output).to include("foo")
        end
      end
    end
  end

  describe "database configuration" do
    context "no active record" do
      it "writes a heroku specific database.yml" do
        Hatchet::Runner.new("default_ruby").deploy do |app, heroku|
          expect(app.output).to     include("Writing config/database.yml to read from DATABASE_URL")
          expect(app.output).not_to include("Your app was upgraded to bundler")
        end
      end
    end

    context "active record 4.1+" do
      it "doesn't write a heroku specific database.yml" do
        Hatchet::Runner.new("activerecord41_scaffold").deploy do |app, heroku|
          expect(app.output).not_to include("Writing config/database.yml to read from DATABASE_URL")
        end
      end
    end
  end
end

describe "Raise errors on specific gems" do
  it "should should raise on sqlite3" do
    before_deploy = -> { run!(%Q{echo "ruby '2.5.4' >> Gemfile"}) }
    Hatchet::Runner.new("sqlite3_gemfile", allow_failure: true, before_deploy: before_deploy).deploy do |app|
      expect(app).not_to be_deployed
      expect(app.output).to include("Detected sqlite3 gem which is not supported")
      expect(app.output).to include("devcenter.heroku.com/articles/sqlite3")
    end
  end
end



describe "No Lockfile" do
  it "should not deploy" do
    Hatchet::Runner.new("no_lockfile", allow_failure: true).deploy do |app|
      expect(app).not_to be_deployed
      expect(app.output).to include("Gemfile.lock required")
    end
  end
end

describe "Rack" do
  it "should not overwrite already set environment variables" do
    custom_env = "FFFUUUUUUU"
    app = Hatchet::Runner.new("default_ruby")
    app.setup!
    app.set_config("RACK_ENV" => custom_env)
    expect(app.run("env")).to match(custom_env)

    app.deploy do |app|
      expect(app.run("env")).to match(custom_env)
    end
  end
end
