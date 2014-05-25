module Police
  class NestedPolicy < Policy
    attr_reader :parent

    def initialize (user, model, parent)
      super(user, model)
      @parent = parent
    end

    # actions
    can :read,  -> { delegate? ? parent.read?  : super() }
    can :write, -> { delegate? ? parent.write? : super() }

    # helpers
    def delegate?
      false
    end
  end
end
