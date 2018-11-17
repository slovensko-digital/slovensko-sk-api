root = File.expand_path('upvs', __dir__)

Dir[File.join(root, 'bin', 'lib', '*.jar')].each { |jar| require jar }

require File.join(root, 'bin', 'upvs-0.0.0.jar')
