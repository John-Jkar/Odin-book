class PagesController < ApplicationController
  # The landing page is the one page a signed out visitor may see.
  skip_before_action :authenticate_user!

  def home
    redirect_to posts_path if user_signed_in?
  end
end
