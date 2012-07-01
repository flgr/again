# Fix a bug in singleton: When the Singleton module is included multiple times
# in the same class, it will reset the instance variable on each inclusion.
#
# Together with again.rb this can easily result in lost state.
# So this version only sets the instance variable to nil if it was undefined.

require 'singleton'

class << Singleton
  alias :included_without_guard :included
  
  def included(klass)
    return if klass.instance_variable_get(:@singleton_included)
    included_without_guard(klass)
    klass.instance_variable_set(:@singleton_included, true)
  end
end
