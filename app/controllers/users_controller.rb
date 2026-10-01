class UsersController < ApplicationController
  def index
    @users = User
      .where.not(id: current_user.id)
      .order(:username)
      .includes(
        follower_relationships: :follower,
        following_relationships: :following
      )

    # Pending requests are not part of the accepted-only associations above, so
    # preload them by id to keep the list at a constant number of queries.
    @pending_sent = current_user.follow_requests_sent.pending
      .index_by(&:following_id)
    @pending_received = current_user.follow_requests_received.pending
      .index_by(&:follower_id)
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.profile_feed_posts
    @pending_request = current_user.follow_requests_sent.find_by(following_id: @user.id)
    @incoming_request = current_user.follow_requests_received
      .pending.find_by(follower_id: @user.id)
  end
end
