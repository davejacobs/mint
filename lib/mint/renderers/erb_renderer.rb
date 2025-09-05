require "erb"

module Mint
  module Renderers
    class Erb
      def self.render(content, variables)
        ERB.new(content).result_with_hash(variables)
      end
    end
  end
end