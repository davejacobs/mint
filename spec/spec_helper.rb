require 'mint'
require 'fakefs/safe'

RSpec::Matchers.define :be_in_directory do |name|
  match do |resource|
    resource.source.dirname.to_s =~ /#{name}/
  end
end
