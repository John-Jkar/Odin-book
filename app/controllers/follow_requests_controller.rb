class FollowRequestsController < ApplicationController
  before_action :set_request

  # Accept an incoming follow request.
  def update
    @relationship.accept!
    redirect_back fallback_location: users_path,
      notice: "#{@relationship.follower.username} is now following you."
  end

  # Decline (or withdraw) a follow request.
  def destroy
    @relationship.destroy!
    redirect_back fallback_location: users_path, notice: "Follow request removed."
  end

  private

  def set_request
    @relationship = current_user.follow_requests_received.find(params[:id])
  end
end
