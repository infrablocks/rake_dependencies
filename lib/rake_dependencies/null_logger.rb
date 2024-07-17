# frozen_string_literal: true

require 'logger'
require 'stringio'

module RakeDependencies
  class NullLogger < Logger
    def initialize
      super(StringIO.new)
    end

    def add(severity, message = nil, progname = nil)
      # no-op
    end

    def <<(msg)
      # no-op
    end

    def ==(other)
      self.class == other.class
    end

    def hash
      self.class.hash
    end
  end
end
