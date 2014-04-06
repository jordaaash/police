require 'police/version'
require 'police/errors'
require 'active_support/dependencies/autoload'
require 'active_support/inflector'
require 'set'
require 'ruby_utils/core_ext/kernel/require'
require 'singleton'

module Police
  extend ActiveSupport::Autoload

  autoload :Policy
  autoload :NestedPolicy

  def police!
    raise NotAuthorized
  end

  def police?
    !!police!
  rescue NotDefined, NotAuthorized
    false
  end

  def authorize! (user, action, *models)
    policy = self.policy(user, *models)
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

  def cannot? (user, action, *models)
    !can?(user, action, *models)
  end

  def owner? (user, *models)
    models.each { |model| authorize!(user, :owner, model) }
    true
  rescue NotDefined, NotAuthorized
    false
  end

  def policy (user, *models)
    raise NotDefined if models.empty?
    if (policy = self.policies(user)[[*models]])
      policy
    else
      policies = self.policies(user)
      cache    = []
      modules  = []
      models.dup.reduce(nil) do |p, m|
        policy_class = self.policy_class(m, *modules)
        cache << (model = models.shift)
        modules << self.model_class(model).to_s.pluralize
        policies[[*cache]] = policy_class.new(user, m, *p)
      end
    end
  end

  def policies (user = nil)
    policies = (@policies ||= PolicyCache.instance)
    user ? (policies[user] ||= {}) : policies
  end

  def policy_class (model, *modules)
    begin
      model_class  = self.model_class(model)
      policy_name  = [*modules, model_class] * '::'
      policy_class = "#{policy_name}Policy".constantize
    rescue NameError
      model = model_class.superclass
      retry unless model_base_classes.include?(model)
    end
    raise NotDefined unless policy_class
    policy_class
  end

  def model_class (model)
    case
    when model.respond_to?(:model_name)
      model.model_name.to_s.constantize
    when model.is_a?(Class)
      model
    when model.class.respond_to?(:model_name)
      model.class.model_name.to_s.constantize
    else
      model.class
    end
  rescue NameError
    raise NotDefined
  end

  class PolicyCache < (require?('ref/weak_key_map') ? Ref::WeakKeyMap : Hash)
    include Singleton
  end

  def model_base_classes
    if @model_base_classes
      @model_base_classes
    else
      model_base_classes = Set[Object, BasicObject, Class, Struct]
      begin
        require 'active_record/base'
        model_base_classes << ActiveRecord::Base
      rescue LoadError
      end
      self.model_base_classes = model_base_classes
    end
  end

  attr_writer :model_base_classes
end
