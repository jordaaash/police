require 'police/policy'

module Police
  class NestedPolicy < Policy
    attr_reader :parent

    def initialize (user, model, parent)
      super(user, model)
      @parent = parent
    end

    # helpers
    def delegate?
      false
    end

    def read?
      delegate? ? parent.read? : super
    end

    def write?
      delegate? ? parent.write? : super
    end

    def scope
      delegate? ? parent.scope : super
    end
  end
end
