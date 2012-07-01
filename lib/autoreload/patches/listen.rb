require 'rubygems'
require 'listen'

class Listen::Adapter
  def self.usable_and_works?(directories, options = {})
    usable? #&& Array(directories).all? { |d| !writable?(d) || works?(d, options) }
  end

  def self.writable?(directory)
    test_file = "#{directory}/.listen_test"
    FileUtils.touch(test_file)
    return true
  rescue SystemCallError
    return false
  ensure
    FileUtils.rm(test_file) if File.exists?(test_file)
  end
end

# class Listen::DirectoryRecord
#   # Don't use content-based modification at all (performance optimization)
#   def content_modified?(path)
#     return true
#   end
# end
