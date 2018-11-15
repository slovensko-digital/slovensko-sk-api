root = File.expand_path('upvs', __dir__)

Dir[File.join(root, 'bin', 'lib', '*.jar')].each { |jar| require jar }

# TODO clean up this
begin
  require File.join(root, 'bin', 'upvs-0.0.0.jar')
rescue LoadError
  `lib/upvs/compile`
  require File.join(root, 'bin', 'upvs-0.0.0.jar')
end
