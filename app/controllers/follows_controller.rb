class FollowsController < ApplicationController
  before_action :set_target_user

  # Send a follow request (or immediately follow when allowed).
  def create
    relationship = Relationship.new(follower: current_user, following: @user)

    if relationship.save
      redirect_back fallback_location: users_path,
        notice: "Follow request sent to #{@user.username}."
    else
      redirect_back fallback_location: users_path,
        alert: relationship.errors.full_messages.to_sentence
    end
  end

  # Unfollow someone, or withdraw a request you have not had accepted yet.
  def destroy
    relationship = Relationship.find_by(follower: current_user, following: @user)

    if relationship&.accepted?
      relationship.destroy!
      redirect_back fallback_location: users_path, notice: "Unfollowed #{@user.username}."
    elsif relationship
      relationship.destroy!
      redirect_back fallback_location: users_path,
        notice: "Follow request to #{@user.username} cancelled."
    else
      redirect_back fallback_location: users_path,
        alert: "You are not following #{@user.username}."
    end
  end

  private

  def set_target_user
    @user = User.find(params[:user_id])
  end
end
