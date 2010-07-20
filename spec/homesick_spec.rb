require 'spec_helper'

describe Homesick do
  before do
    @homesick = Homesick.new
  end

  describe "clone" do
    it "should symlink existing directories" do
      somewhere = create_construct
      somewhere.directory('wtf')
      wtf = somewhere + 'wtf'

      @homesick.should_receive(:ln_s).with(wtf.to_s, wtf.basename)

      @homesick.clone wtf.to_s
    end

    it "should clone git repo like git://host/path/to.git" do
      @homesick.should_receive(:git_clone).with('git://github.com/technicalpickles/pickled-vim.git')

      @homesick.clone "git://github.com/technicalpickles/pickled-vim.git"
    end

    it "should clone git repo like git@host:path/to.git" do
      @homesick.should_receive(:git_clone).with('git@github.com:technicalpickles/pickled-vim.git')

      @homesick.clone 'git@github.com:technicalpickles/pickled-vim.git'
    end

    it "should clone git repo like http://host/path/to.git" do
      @homesick.should_receive(:git_clone).with('http://github.com/technicalpickles/pickled-vim.git')

      @homesick.clone 'http://github.com/technicalpickles/pickled-vim.git'
    end

    it "should clone a github repo" do
      @homesick.should_receive(:git_clone).with('git://github.com/wfarr/dotfiles.git', :destination => Pathname.new('wfarr/dotfiles'))

      @homesick.clone "wfarr/dotfiles"
    end
  end

  describe "list" do

    # FIXME only passes in isolation. need to setup data a bit better
    xit "should say each castle in the castle directory" do
      @user_dir.directory '.homesick/repos' do |repos_dir|
        repos_dir.directory 'zomg' do |zomg|
          Dir.chdir do
            system "git init >/dev/null 2>&1"
            system "git remote add origin git://github.com/technicalpickles/zomg.git >/dev/null 2>&1"
          end
        end

        repos_dir.directory 'wtf/zomg' do |zomg|
          Dir.chdir do
            system "git init >/dev/null 2>&1"
            system "git remote add origin git://github.com/technicalpickles/zomg.git >/dev/null 2>&1"
          end
        end
      end

      @homesick.should_receive(:say_status).with("zomg", "git://github.com/technicalpickles/zomg.git", :cyan)
      @homesick.should_receive(:say_status).with("wtf/zomg", "git://github.com/technicalpickles/zomg.git", :cyan)

      @homesick.list
    end

  end

  describe 'track' do

    before(:each) do
      @repo_dir = @user_dir.directory '.homesick/repos/somecastle/home'
    end

    after(:each) do
      @repo_dir.destroy!
    end

    it "should move and symlink a file" do
      @user_dir.file '.fakerc'

      @homesick.should_receive(:git_add).with('.fakerc')
      @homesick.track(@user_dir + '.fakerc', 'somecastle')
      File.symlink?(@user_dir + '.fakerc').should be true
      File.exist?(@repo_dir + '.fakerc').should be true
    end

    it "should move and symlink a directory" do
      @user_dir.directory '.somedir'

      @homesick.should_receive(:git_add).with('.somedir')
      @homesick.track(@user_dir + '.somedir', 'somecastle')
      File.symlink?(@user_dir + '.somedir').should be true
      File.exist?(@repo_dir + '.somedir').should be true
    end

  end

  describe 'commit' do
    it "should commit the castle" do
      repo_dir = @user_dir.directory '.homesick/repos/somecastle/home'
      @homesick.should_receive(:git_commit).with('my commit')
      @homesick.commit('somecastle', 'my commit')
    end
  end

  describe 'push' do
    it "should push to the repo" do
      repo_dir = @user_dir.directory '.homesick/repos/somecastle/home'
      @homesick.should_receive(:git_push)
      @homesick.push('somecastle')
    end
  end

end
