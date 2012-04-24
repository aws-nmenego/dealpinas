class SessionsController < ApplicationController
  
  def new
    @do_not_display_signin = true;
    
    # find random ad
    @deal = Deal.where(:is_ad => true).find(:first, :order => "RAND()")
    
  end
  
  def create
   user = User.authenticate(params[:session][:email],
                             params[:session][:password])
    if user.nil?
      flash[:error] = "Invalid email/password combination."
      redirect_to signin_path
    else
      sign_in_user user
      redirect_back_or root_path
    end
  end

  def destroy
    sign_out_user
    redirect_to root_path
  end

end
