lib_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH << lib_dir

require 'autoreload'

if __FILE__ == $0 then
  puts "AutoReload loaded"
  AutoReload.join
end
