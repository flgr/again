class AutoReload
  def self.open_cmd()
    (`which mate` rescue nil || "open").chomp
  end
  
  def self.open_lib(lib, cmd=open_cmd)
    if lib = instance.resolve_library(lib) then
      system(cmd, lib)
    end
  end
  
  def self.open_libdir(lib, cmd=open_cmd)
    if lib = instance.resolve_library(lib) then
      system(cmd, File.dirname(lib))
    end
  end
end
