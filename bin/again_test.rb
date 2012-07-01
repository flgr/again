lib_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$LOAD_PATH << lib_dir

require 'again'

if __FILE__ == $0 then
  puts "Again loaded"
  Again.join
end
