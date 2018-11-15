root = File.expand_path('upvs', __dir__)
main = File.join(root, 'bin', 'upvs-0.0.0.jar')

system(ENV, File.join(root, 'compile')) unless File.exists?(main)

Dir[File.join(root, 'bin', 'lib', '*.jar')].each { |jar| require jar }

require main
