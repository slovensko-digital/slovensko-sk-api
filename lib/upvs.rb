root = File.expand_path('upvs', __dir__)

system File.join(root, 'compile') if Dir.empty? File.join(root, 'bin')

Dir[File.join(root, 'bin', 'lib', '*.jar')].each { |jar| require jar }

require File.join(root, 'bin', 'upvs-0.0.0.jar')
