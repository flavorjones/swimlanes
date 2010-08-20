module Swimlanes
  class Importer
    attr_accessor :path

    def initialize path
      @path = path
    end

    def to_js method_name='swim'
      js = []
      js << "function #{method_name}(canvasId) {"
      js << "  var s = new SwimLanes(canvasId);"
      branches.sort.each_with_index do |branch, j|
        js << "  s.addBranch('#{branch}',#{j});"
      end
      js << "}"
      js.join("\n")
    end

    private

    def branches
      Dir.chdir(path) do
        run("git branch | cut -c3-").split
      end
    end

    def run cmd
      %x(#{cmd})
    end
  end
end
