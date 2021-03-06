require "language_pack/shell_helpers"
module LanguagePack::Installers; end

# This is a base module that is later included by other
# classes such as LanguagePack::Installers::HerokuRubyInstaller
#
module LanguagePack::Installers::RubyInstaller
  include LanguagePack::ShellHelpers

  attr_reader :fetcher

  DEFAULT_BIN_DIR = "bin"

  def self.installer(ruby_version)
    if ruby_version.rbx?
      LanguagePack::Installers::RbxInstaller
    else
      LanguagePack::Installers::HerokuRubyInstaller
    end
  end

  def install(ruby_version, install_dir)
    fetch_unpack(ruby_version, install_dir)
    setup_binstubs(install_dir)
  end

  def setup_binstubs(install_dir)
    FileUtils.mkdir_p DEFAULT_BIN_DIR
    run("ln -s ruby #{install_dir}/bin/ruby.exe")

    install_pathname = Pathname.new(install_dir)
    Dir["#{install_dir}/bin/*"].each do |vendor_bin|
      # for Ruby 2.6.0+ don't symlink the Bundler bin so our shim works
      next if vendor_bin.include?("bundle")

      # The bin/rake binstub generated when compiling ruby does not load bundler
      # which can cause unexpected failures. Deleting this binstub allows two things:
      #
      #   - If the app includes a custom binstub allows it to be used
      #   - If the app does not include a custom binstub, then it will fall back to vendor/bundle/bin/rake
      #     which is generated by bundler
      #
      # Discussion: https://github.com/heroku/heroku-buildpack-ruby/issues/1025#issuecomment-653102430
      next if vendor_bin.include?("rake")

      if install_pathname.absolute?
        run("ln -s #{vendor_bin} #{DEFAULT_BIN_DIR}")
      else
        run("ln -s ../#{vendor_bin} #{DEFAULT_BIN_DIR}")
      end
    end
  end
end
