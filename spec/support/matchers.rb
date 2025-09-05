RSpec::Matchers.define :be_in_directory do |name|
  match {|resource| resource.source_directory =~ /#{name}/ }
end

RSpec::Matchers.define :be_path do |name|
  match {|resource| resource == Pathname.new(name) }
end

RSpec::Matchers.define :be_in_template do |name|
  match {|file| file =~ /#{Mint::PROJECT_ROOT}.*#{name}/ }
end

RSpec::Matchers.define :be_a_template do |name|
  match {|file| Mint.template? file }
end
