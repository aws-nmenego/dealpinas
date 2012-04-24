module SessionsHelper

  # sign in permanently until explicitly signed out
  def sign_in_user(user)
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    # for controller and view access
    self.current_site_user = user
  end
  
  # setter
  def current_site_user=(user) 
    @current_site_user = user
  end
  
  def allowed_to_edit_locations? 
    return current_site_user ? ( current_site_user.user_type[:type_name] == 'Admin' ) : false
  end

  # get user from the cookie jar!
  def current_site_user
    @current_site_user = user_from_remember_token || nil
  end
  
  def user_signed_in?
    !current_site_user.nil?
  end
  
  def sign_out_user
    cookies.delete(:remember_token)
    self.current_site_user = nil
  end
  
  def deny_user_access
    redirect_to signin_path, :notice => "Please sign in to access this page."
  end
  
  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  
  private

  def user_from_remember_token
    # * use two-element array
    User.authenticate_with_salt(*remember_token)
  end
  
  def clear_return_to
   session[:return_to] = nil
 end  
 
  private 
    def remember_token
      cookies.signed[:remember_token] || [nil, nil]
    end
end