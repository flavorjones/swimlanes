module Swimlanes
  class Importer
    attr_accessor :path

    def initialize path
      @path = path
    end

    def to_js *arguments
      options = arguments.last.is_a?(Hash) ? arguments.pop : {}
      branches = arguments

      options[:function] ||= 'swim'

      [].tap do |js|
        js << "function #{options[:function]}(canvasId) {"
        js << "  var s = new SwimLanes(canvasId);"
        branches.each_with_index do |branch, j|
          js << "  s.addBranch('#{branch}',#{j});"
        end
        js << "}"
      end.join("\n")
    end

    private

    def run cmd
      %x(#{cmd})
    end
  end
end
