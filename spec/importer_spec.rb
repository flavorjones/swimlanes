require File.join(File.dirname(__FILE__),"spec_helper.rb")

describe Swimlanes::Importer do
  def run cmd
    if $DEBUG
      puts "=> #{cmd}"
      system(cmd) || raise("command #{cmd} failed")
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

      it "should accept a method name, and emit it" do
        @importer.to_js("drawSwimlanes").should =~ %r/function drawSwimlanes()/
      end

      it "should emit a swimlane variable" do
        @importer.to_js("drawSwimlanes").should =~ %r/var s = new SwimLanes\(\);/
      end

      context "branches" do
        before do
          Dir.chdir(@repo_path) do
            run "git checkout -b branch1 master"
            run "git checkout -b branch2 master"
          end
        end

        it "should emit code for branches" do
          js = @importer.to_js("drawSwimlanes")
          js.should =~ %r/s.addBranch\('branch1',0\);/
          js.should =~ %r/s.addBranch\('branch2',1\);/
          js.should =~ %r/s.addBranch\('master',2\);/
        end
      end
    end
  end
end
