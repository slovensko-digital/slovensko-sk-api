# require Java libraries

root = File.expand_path('upvs', __dir__)

Dir[File.join(root, 'bin', 'lib', '*.jar')].each { |jar| require jar }

require File.join(root, 'bin', 'upvs-0.0.0.jar')

# alter Java classes for Ruby usage

class digital::slovensko::upvs::UpvsProxy
  %w(iam sktalk).each { |scope| alias_method(scope, "get_#{scope}_proxy") }
end
