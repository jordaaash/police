require 'police'
require 'police/errors'
require 'active_support/core_ext/class/attribute'
require 'action_controller/base'

module Police
  module Controller
    def police (options = {}, &block)
      options     = {
        :user_method => :current_user,
        :user_class  => 'User'
      }.merge!(options)
      user_method = options.delete :user_method
      user_class  = options.delete :user_class

      include Police
      include InstanceMethods

      class_attribute :police_user_method, :police_user_class
      self.police_user_method = user_method
      self.police_user_class  = user_class

      helper_method :police_user, :can?, :owner?
      before_action :police!, options, &block
    end

    module InstanceMethods
      private

      def can? (action, *models)
        super(police_user, action, *models)
      end

      def owner? (*models)
        super(police_user, *models)
      end

      def policed_scope (*models)
        super(police_user, *models)
      end

      def policed_find (*models, ids)
        super(police_user, *models, ids)
      end

      def police_user
        if @police_user
          @police_user
        else
          unless (police_user = send police_user_method)
            police_user = police_user_class && police_user_class.new
          end
          @police_user = police_user
        end
      end

      def police_user_method
        self.class.police_user_method
      end

      def police_user_class
        self.class.police_user_class
      end
    end
  end
end

ActionController::Base.send :extend, Police::Controller
