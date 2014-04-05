require 'police/version'
require 'police/errors'
require 'active_support/dependencies/autoload'
require 'active_support/inflector'
require 'set'

module Police
  extend ActiveSupport::Autoload

  autoload :Policy
  autoload :NestedPolicy

  private

  def policy_classes
    if @policy_classes
      @policy_classes
    else
      policy_classes = Set[Object, BasicObject, Class, Struct]
      begin
        require 'active_record/base'
        policy_classes << ActiveRecord::Base
      rescue LoadError
      end
      @policy_classes = policy_classes.freeze
    end
  end

  attr_writer :policy_classes

  def police!
    raise NotAuthorized
  end

  def authorize! (user, action, *models)
    policy = get_policy(user, *models)
    method = :"#{action}?"
    raise NotDefined unless policy.respond_to? method
    raise NotAuthorized unless policy.public_send method
    policy
  end

  def authorized? (user, action, *models)
    !!authorize!(user, action, *models)
  rescue NotDefined, NotAuthorized
    false
  end

  alias_method :can?, :authorized?

  def owner? (user, *models)
    policy = get_policy(user, *models)
    models.each do |model|
      return false unless policy.respond_to?(:owner?) && policy.owner?(model)
    end
    true
  rescue NotDefined, NotAuthorized
    false
  end

  def policed_scope (user, *models)
    get_policy(user, *models).scope
  end

  def policed_find (user, *models, ids)
    get_policy(user, *models).find(ids)
  end

  def get_policy (user, *models)
    raise NotDefined if models.empty?
    if (policy = get_policies(user)[[*models]])
      policy
    else
      policies = get_policies(user)
      cache    = []
      modules  = []
      models.dup.reduce(nil) do |p, m|
        policy_class = get_policy_class(m, *modules)
        cache << (model = models.shift)
        modules << get_model_class(model).to_s.pluralize
        policies[[*cache]] = policy_class.new(user, m, *p)
      end
    end
  end

  def get_policies (user = nil)
    policies = @policies ||= {}
    user ? (policies[user] ||= {}) : policies
  end

  def get_policy_class (model, *modules)
    begin
      model_class  = get_model_class(model)
      policy_name  = [*modules, model_class] * '::'
      policy_class = "#{policy_name}Policy".constantize
    rescue NameError
      model = model_class.superclass
      retry unless policy_classes.include?(model)
    end
    raise NotDefined unless policy_class
    policy_class
  end

  def get_model_class (model)
    case
    when model.respond_to? :model_name
      model.model_name.to_s.constantize
    when model.is_a? Class
      model
    when model.class.respond_to? :model_name
      model.class.model_name.to_s.constantize
    else
      model.class
    end
  rescue NameError
    raise NotDefined
  end
end
