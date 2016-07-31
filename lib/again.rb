require 'again/version'
require 'again/extras'
require 'again/patches'

require 'set'
require 'pathname'
require 'tmpdir'
require 'singleton'
require 'fileutils'

require 'rubygems'
require 'listen'

class Again
  include Singleton

  def self.start() self.instance end
  def self.join() instance.join end
  def self.reloaded?() instance.reloaded? end

  def reloaded?() @reloaded end

  def join()
    # Can't simply join @watch_thread here as a refresh() can stop it.
    # We want to survive refreshes so we instead join a thread which
    # keeps checking for new watch_threads...
    Thread.new do
      loop do
        if @watch_thread then
          @watch_thread.alive?() ? @watch_thread.join : sleep(0.5)
        end
      end
    end.join
  end

  private

  def with_reloaded()
    old_reloaded, @reloaded = @reloaded, true
    yield
  ensure
    @reloaded = old_reloaded
  end

  def initialize()
    @reloaded, @handler = false, nil
    @watch_threads = ThreadGroup.new
    @full_prog_name = File.expand_path($PROGRAM_NAME)
    refresh()
  end

  def refresh()
    refresh_libraries
    refresh_handler
  end

  def refresh_libraries()
    @base_paths = find_base_paths()
    @libraries = find_libraries()
  end

  def find_features()
    features = $LOADED_FEATURES.dup

    # Allow realoding of main file (which is not a loaded library
    # and thus does not appear in $LOADED_FEATURES)
    features << @full_prog_name

    # features doesn't include this file by default since
    # technically it is still in the process of being loaded
    # ...so manually include it
    features << File.basename(__FILE__)

    return features
  end

  # Avoid warnings on self-reload
  remove_const(:JRUBY_PSEUDO_LIBS) if defined?(JRUBY_PSEUDO_LIBS)
  remove_const(:PSEUDO_LIBS) if defined?(PSEUDO_LIBS)

  # Probably incomplete...
  JRUBY_PSEUDO_LIBS = %w(enumerable.jar enumerator.jar thread.rb tempfile.rb
    java.rb jruby.rb socket.jar strscan.jar iconv.jar stringio.jar etc.jar
    fcntl.rb timeout.rb digest/md5.jar jsignal_internal.rb rbconfig.rb
    jruby/util.rb digest/sha1.jar digest.jar jruby/path_helper.rb)

  PSEUDO_LIBS = %w(enumerable.so enumerator.so thread.rb rational.so complex.so)

  PSEUDO_LIBS.push(*JRUBY_PSEUDO_LIBS) if defined? JRUBY_VERSION

  def pseudo_lib?(lib) PSEUDO_LIBS.include?(lib) end

  RELOAD_MARKER = "--reload-temp--" unless defined?(RELOAD_MARKER)

  def find_base_paths()
    base_paths = *$LOAD_PATH.uniq
    base_paths << File.dirname(@full_prog_name)

    base_paths.map! { |path| File.expand_path(path) }
    base_paths.reject! { |path| not File.exist?(path) or path.include?(RELOAD_MARKER) }
    base_paths.uniq!

    return base_paths
  end

  def find_libraries()
    libraries, features = Set[], find_features

    features.each do |rel_lib|
      next if rel_lib.include?(RELOAD_MARKER)

      res_lib = resolve_library(rel_lib)

      if res_lib then
        libraries << res_lib
      elsif not pseudo_lib?(rel_lib) then
        warn "Failed to resolve library %s to full path" % rel_lib
      end
    end

    return libraries
  end

  def resolve_library(rel_lib)
    return rel_lib if Pathname.new(rel_lib).absolute?

    @base_paths.each do |path|
      full_lib = File.join(path, rel_lib)
      return full_lib if File.exist?(full_lib)
    end

    return nil
  end

  def refresh_handler()
    # Our old @watch_thread will finish running after this
    @handler.stop if @handler

    @handler = Listen.to(*@base_paths, &method(:on_change))
    @watch_thread = Thread.new { @handler.start }
  end

  def on_change(modified, added, removed)
    (modified + added).each do |path|
      reload(path) if @libraries.include?(path)
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
    tmp_dir = nil

    if @full_prog_name == path then
      time = Time.now.to_i.to_s
      tmp_dir = File.join(Dir.tmpdir, RELOAD_MARKER + "-dir-" + time)
      Dir.mkdir(tmp_dir)

      load_path = File.join(tmp_dir, RELOAD_MARKER + File.basename(load_path))

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

    # need to do this from separate thread...
    # we can not call handler.stop() from the thread
    # that is getting the handler's callback
    Thread.new { refresh }
  ensure
    FileUtils.rm_rf(tmp_dir) if tmp_dir
  end
end

Again.start

if Again.reloaded? then
  puts "Again reloaded"
end
