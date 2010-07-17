require 'rubygems'
require 'thor'

class Homesick < Thor
  autoload :Shell, 'homesick/shell'
  autoload :Actions, 'homesick/actions'

  include Thor::Actions
  include Homesick::Actions

  add_runtime_options!

  GITHUB_NAME_REPO_PATTERN = /\A([A-Za-z_-]+\/[A-Za-z_-]+)\Z/

  def initialize(args=[], options={}, config={})
    super
    self.shell = Homesick::Shell.new
  end

  desc "clone URI", "Clone +uri+ as a castle for homesick"
  def clone(uri)
    inside repos_dir do
      destination = nil
      if File.exist?(uri)
        destination = Pathname.new(uri).basename

        ln_s uri, destination
      elsif uri =~ GITHUB_NAME_REPO_PATTERN
        destination = Pathname.new($1)
        git_clone "git://github.com/#{$1}.git", :destination => destination
      else
        if uri =~ /\/([^\/]*).git\Z/
          destination = Pathname.new($1)
        end

        git_clone uri
      end

      if destination.join('.gitmodules').exist?
        inside destination do
          git_submodule_init
          git_submodule_update
        end
      end
    end
  end

  desc "pull NAME", "Update the specified castle"
  def pull(name)
    check_castle_existance(name, "pull")

    inside repos_dir.join(name) do
      git_pull
      git_submodule_init
      git_submodule_update
    end
  end

  desc "symlink NAME", "Symlinks all dotfiles from the specified castle"
  def symlink(name)
    check_castle_existance(name, "symlink")

    inside castle_dir(name) do
      files = Pathname.glob('.*').reject{|a| [".",".."].include?(a.to_s)}
      files.each do |path|
        absolute_path = path.expand_path

        inside home_dir do
          adjusted_path = (home_dir + path).basename

          ln_s absolute_path, adjusted_path
        end
      end
    end
  end

  desc "list", "List cloned castles"
  def list
    #require 'ruby-debug'; breakpoint
    Pathname.glob("#{repos_dir}/**/*/.git") do |git_dir|
      castle = git_dir.dirname
      Dir.chdir castle do # so we can call git config from the right contxt
        say_status castle.relative_path_from(repos_dir), `git config remote.origin.url`.chomp, :cyan
      end
    end
  end

  desc "generate PATH", "generate a homesick-ready git repo at PATH"
  def generate(castle)
    castle = Pathname.new(castle).expand_path

    github_user = `git config github.user`.chomp
    github_user = nil if github_user == ""
    github_repo = castle.basename


    empty_directory castle
    inside castle do
      git_init
      if github_user
        url = "git@github.com:#{github_user}/#{github_repo}.git"
        git_remote_add 'origin', url
      end

      empty_directory "home"
    end
  end

  desc "track <file/dir>", "add a file or directory you'd like to track"
  def track(filename, castlename)
    FileUtils.mv filename, castle_dir(castlename)
    ln_s castle_dir(castlename) + File.basename(filename), filename
    git_add(castle_dir(castlename) + File.basename(filename))
  end

  protected

  def home_dir
    @home_dir ||= Pathname.new(ENV['HOME'] || '~').expand_path
  end

  def repos_dir
    @repos_dir ||= home_dir.join('.homesick', 'repos').expand_path
  end

  def castle_dir(name)
    repos_dir.join(name, 'home')
  end

  def check_castle_existance(name, action)
    unless castle_dir(name).exist?
      say_status :error, "Could not #{action} #{name}, expected #{castle_dir(name)} exist and contain dotfiles", :red

      exit(1)
    end
  end

end
