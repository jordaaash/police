require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/attribute'
require 'action_controller/base'

module Police
  module Controller
    def police (options = {}, &block)
      options    = {
        user:       :current_user,
        user_class: 'User'
      }.merge!(options)
      user       = options.delete :user
      user_class = options.delete :user_class

      police_user = []
      police_user << "#{user}" if user
      police_user << "#{user_class}.new" if user_class
      police_user << 'nil' if police_user.empty?
      police_user = police_user.compact.join(' || ')

      include Police
      include InstanceMethods

      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def police_user                   # def police_user
          @police_user ||= #{police_user} #   @police_user ||= current_user || User.new
        end                               # end
      RUBY_EVAL

      hide_action   :model_base_classes, :policies, :policy_class, :model_class
      helper_method :police!, :police?, :authorize!, :authorized?, :can?,
                    :cannot?, :owner?, :policy
      before_action :police!, options, &block
    end

    module InstanceMethods
      def authorize! (user, action, *models)
        if user.nil?
          user = police_user
        elsif user.is_a?(Symbol) || user.is_a?(String)
          models.unshift(action)
          user, action = police_user, user
        end
        super
      end
    end
  end
end

ActionController::Base.send :extend, Police::Controller
