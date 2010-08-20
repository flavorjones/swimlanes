require File.join(File.dirname(__FILE__),"spec_helper.rb")

describe Swimlanes::Importer do
  def run cmd
    if $DEBUG
      puts "=> #{cmd}"
      system("#{cmd} 2>&1") || raise("command #{cmd} failed")
    else
      system("#{cmd} > /dev/null 2>&1") || raise("command #{cmd} failed")
    end
  end

  describe ".new" do
    it "should raise an exception when not passed any arguments" do
      proc { Swimlanes::Importer.new }.should raise_error
    end

    it "should accept a path attribute" do
      Swimlanes::Importer.new("/foo/bar").path.should == "/foo/bar"
    end
  end

  describe ".to_js" do
    context "a valid git repository" do
      before do
        @repo_path = "tmp/demo-repo"
        FileUtils.mkdir_p @repo_path

        Dir.chdir(@repo_path) do
          run "git init"
          run "touch foo"
          run "git add ."
          run "git commit -m 'first commit'"
        end

        @importer = Swimlanes::Importer.new @repo_path
      end

      after do
        FileUtils.rm_rf @repo_path
      end

      context "multiple branches" do
        before do
          Dir.chdir(@repo_path) do
            run "git checkout -b branch1 master"
            run "git checkout -b branch2 master"
          end
        end
        
        it "accepts no arguments and emits all branches" do
          js = @importer.to_js
          js.should =~ %r/s.addBranch\('branch1',\d+\);/
          js.should =~ %r/s.addBranch\('branch2',\d+\);/
          js.should =~ %r/s.addBranch\('master',\d+\);/
        end

        it "accepts a list of branch names and emits only those branches in order" do
          js = @importer.to_js 'branch1', 'branch2'
          js.should =~ %r/s.addBranch\('branch1',0\);/
          js.should =~ %r/s.addBranch\('branch2',1\);/
          js.should_not =~ %r/s.addBranch\('master',\d+\);/

          js = @importer.to_js 'branch2', 'master'
          js.should =~ %r/s.addBranch\('branch2',0\);/
          js.should =~ %r/s.addBranch\('master',1\);/
          js.should_not =~ %r/s.addBranch\('branch1',\d+\);/

          js = @importer.to_js 'master', 'branch1'
          js.should =~ %r/s.addBranch\('master',0\);/
          js.should =~ %r/s.addBranch\('branch1',1\);/
          js.should_not =~ %r/s.addBranch\('branch2',\d+\);/
        end

        it "accepts a list of branch names and silently ignores non-existent branches" do
          pending
          js = @importer.to_js 'master', 'foo', 'branch1', 'bar'
          js.should =~ %r/s.addBranch\('master',0\);/
          js.should =~ %r/s.addBranch\('branch1',1\);/
          js.should_not =~ %r/s.addBranch\('branch2',\d+\);/
          js.should_not =~ %r/s.addBranch\('foo',\d+\);/
          js.should_not =~ %r/s.addBranch\('bar',\d+\);/
        end

        it "emits a function named 'swim'" do
          @importer.to_js.should =~ %r/function swim\(canvasId\)/
        end

        it "accepts a function name option and emits the function named properly" do
          @importer.to_js(:function => 'foo').should =~ %r/function foo\(canvasId\)/
        end

        it "accepts branch names and options" do
          js = @importer.to_js('master', :function => 'foo')
          js.should =~ %r/s.addBranch\('master',0\);/
          js.should_not =~ %r/s.addBranch\('branch1',1\);/
          js.should_not =~ %r/s.addBranch\('branch2',\d+\);/
          js.should =~ %r/function foo\(canvasId\)/
        end

        it "should emit a swimlane variable" do
          @importer.to_js.should =~ %r/var s = new SwimLanes\(canvasId\);/
        end
      end

      context "commits and branches" do
        before do
          Dir.chdir(@repo_path) do
            run "touch foo1 && git add foo1"
            run "git commit -a -m 'commit 1'"
            run "git checkout -b branch1 master"
            run "touch foo2 && git add foo2"
            run "git commit -a -m 'commit 2'"
            run "git checkout -b branch2 master"
            run "touch foo3 && git add foo3"
            run "git commit -a -m 'commit 3'"
          end
        end

        context "with no arguments" do
          it "should order the branches in chronological order of first commit on each" do
            js = @importer.to_js
            js.should =~ %r/s.addBranch\('master',0\);.*s.addBranch\('branch1',1\);.*s.addBranch\('branch2',2\);/m
          end
        end
      end
    end
  end
end
