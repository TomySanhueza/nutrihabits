class ApplicationController < ActionController::Base
  # before_action :authenticate_nutritionist!
  
  def after_sign_in_path_for(resource)
    if resource.is_a?(Nutritionist)
      nutritionist_dashboard_path
    else
      super
    end
  end
end
