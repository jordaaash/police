require 'police/gem_version'

module Police
  # Returns the version of the currently loaded Police as a <tt>Gem::Version</tt>
  def self.version
    gem_version
  end
end
