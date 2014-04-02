module Police
  class Policy
    attr_reader :user, :model, :klass

    def initialize (user, model)
      @user  = user
      @model = model
      @klass = model.is_a?(Class) ? model : model.class
    end

    # actions
    def index?
      list?
    end

    def show?
      read?
    end

    def create?
      write?
    end

    def new?
      create?
    end

    def update?
      write?
    end

    def edit?
      update?
    end

    def destroy?
      write?
    end

    # scope
    def index
      scope
    end

    def find (*args)
      scope.find(*args)
    end

    # helpers
    def class?
      model == klass
    end

    def owner? (object = model)
      false
    end

    def list?
      read?
    end

    def read?
      allow
    end

    def write?
      class? || owner?
    end

    def scope
      klass.all
    end

    def allow
      true
    end

    def deny
      false
    end
  end
end
