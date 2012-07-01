require 'autoreload/version'
require 'autoreload/extras'
require 'autoreload/patches'

require 'set'
require 'pathname'
require 'tempfile'
require 'singleton'
require 'fileutils'

require 'rubygems'
require 'watchr'

class AutoReload
  RELOAD_MARKER = "--reload-temp--" unless defined?(RELOAD_MARKER)

  include Singleton 
  
  attr_reader :watch_thread

  def self.start() self.instance end
  
  def self.watch_thread()
    instance.watch_thread
  end
  
  def self.join()
    watch_thread.join
  end
  
  def self.reloaded?()
    instance.reloaded?
  end

  def reloaded?() @reloaded end

  def with_reloaded()
    old_reloaded, @reloaded = @reloaded, true
    yield
  ensure
    @reloaded = old_reloaded
  end
    
  def initialize()
    @reloaded = false

    # Watchr uses ruby-fsevent (which is outdated and no longer maintained)
    # by requiring 'fsevent' on Mac OS X. It causes severe hiccups with
    # event handlers and stalls for me.
    #
    # It might be a good idea to switch watchr over to rb-fsevent by
    # requiring 'rb-fsevent' and writing a new event_handler for it in
    # the future. But this does seem like a bit of work. So let's use
    # polling for now by disabling FSE completely.
    Watchr.instance_eval do
      remove_const(:HAVE_FSE)
      const_set(:HAVE_FSE, false)
    end

    @handler = nil
    refresh
  end

  def refresh()
    @full_prog_name = Pathname.new(File.expand_path($PROGRAM_NAME))
    @libraries = find_libraries()
    
    if not @handler
      @handler = Watchr.handler.new
      @handler.add_observer(self)
      @watch_thread = Thread.new { @handler.listen(@libraries) }
    else
      @handler.refresh(@libraries)
    end
  end
  
  def find_libraries()
    libraries = Set[]

    features = $LOADED_FEATURES
    
    # features doesn't include this file by default since
    # technically it is still in the process of being loaded
    # ...so manually include it
    features += [File.basename(__FILE__)]
    features.uniq!

    features.each do |rel_lib|
      next if rel_lib.include?(RELOAD_MARKER)
      
      res_lib = resolve_library(rel_lib)
        
      pseudo_libs = %w(enumerable.so enumerator.so)
      
      if defined? JRUBY_VERSION
        # Probably incomplete...
        pseudo_libs += %w(enumerable.jar enumerator.jar tempfile.rb etc.jar rbconfig.rb jruby/util.rb)
      end
        
      if res_lib then
        libraries << Pathname.new(res_lib)
      elsif not pseudo_libs.include?(rel_lib) then
        warn "Failed to resolve library %s to full path" % rel_lib
      end
    end

    if File.exist?(@full_prog_name) then
      libraries << Pathname.new(@full_prog_name)
    end
    
    return libraries
  end
  
  def resolve_library(rel_lib)
    return rel_lib if Pathname.new(rel_lib).absolute?
    
    base_paths = *$LOAD_PATH.uniq
    
    base_paths << File.dirname(@full_prog_name) if File.exist?(@full_prog_name)
    base_paths.uniq!

    base_paths.each do |path|
      full_lib = File.join(path, rel_lib)

      if File.exist?(full_lib) then
        return full_lib
      end
    end
    
    return nil
  end
      
  def update(path, event_type = nil)
    if event_type == :modified or event_type == nil then
      if @libraries.include?(path) then
        reload(path)
      end
    end
  end
  
  def reload(path)
    STDERR.puts "Reloading %s" % path
    
    # We don't want __FILE__ == $0 conditions to evaluate to true on reloads
    # to avoid duplicate startup logic execution issues...
    #
    # So we intentionally create a copy of the file in that case to make
    # those checks evaluate to false.
    
    load_path = path
    tmp_file = nil
    
    if @full_prog_name == path then
      tmp_name = RELOAD_MARKER + File.basename(load_path)
      tmp_file = Tempfile.open(tmp_name)
      load_path = tmp_file.path
      
      begin
        # Try to hardlink first...
        FileUtils.ln(path, load_path)
      rescue Exception
        # ...if that fails, create a copy.
        FileUtils.copy(path, load_path)
      end
    end
    
    begin
      with_reloaded { load(load_path) }
    rescue Exception => e
      STDERR.puts e, "", e.backtrace.join("\n")
    end

    refresh
  ensure
    tmp_file.unlink if tmp_file
  end
end

AutoReload.start

if AutoReload.reloaded? then
  puts "AutoReload reloaded"
end
