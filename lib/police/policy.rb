require 'active_support/core_ext/array/wrap'

module Police
  class Policy
    attr_reader :user, :model, :klass

    class << self
      ##
      # :method: can
      #
      # :call-seq: can(actions, permission, &block)
      #
      # DSL for generating policy action methods
      # Aliased at allow
      def can (actions, permission = nil, &block)
        permit(actions, permission, true, &block)
      end

      alias_method :allow, :can

      ##
      # :method: cannot
      #
      # :call-seq: cannot(actions, permission, &block)
      #
      # DSL for generating policy action methods
      # Aliased at deny
      def cannot (actions, permission = nil, &block)
        permit(actions, permission, false, &block)
      end

      alias_method :deny, :can

      def permit (actions, permission = nil, condition = true, &block)
        unless block
          block = if permission.nil? || permission == true
                    -> { true }
                  elsif !permission
                    -> { false }
                  elsif permission.is_a?(Symbol)
                    -> { public_send(:"#{permission}?") }
                  elsif permission.respond_to?(:call)
                    permission
                  else
                    raise ArgumentError, 'Invalid permission provided'
                  end
        end
        block = -> { !instance_exec &block } unless condition
        Array.wrap(actions).each { |action| define_method :"#{action}?", &block }
      end
    end

    def initialize (user, model)
      @user  = user
      @model = model
      @klass = model.is_a?(Class) ? model : model.class
    end

    ##
    # :method: read?
    #
    # User can read models of the policy's type by default
    can :read

    ##
    # :method: write?
    #
    # User can write models if it's a Class or is an instance the user owns
    can :write, -> { class? || owner? }

    ##
    # :method: index?
    #
    # User can see the index action if the user can list models
    can :index, :list

    ##
    # :method: list?
    #
    # User can list models if the user can read models

    ##
    # :method: show?
    #
    # User can show models if the user can read models
    can [:list, :show], :read

    ##
    # :method: create?
    #
    # User can create models if the user can write models

    ##
    # :method: update?
    #
    # User can update models if the user can write models

    ##
    # :method: destroy?
    #
    # User can destroy models if the user can write models
    can [:create, :update, :destroy], :write

    ##
    # :method: new?
    #
    # User can see the new model action if the user can create models
    can :new, :create

    ##
    # :method: edit?
    #
    # User can see the edit model action if the user can create models
    can :edit, :update

    # lists
    def index
      all
    end

    # finders
    def all
      klass.all
    end

    def find (*args)
      all.find(*args)
    end

    # helpers
    def class?
      model == klass
    end

    def owner? (object = model)
      object == user
    end
  end
end
