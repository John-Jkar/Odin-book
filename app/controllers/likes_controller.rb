class LikesController < ApplicationController
  before_action :set_post

  def create
    current_user.likes.find_or_create_by!(post: @post)
    redirect_back fallback_location: posts_path,
      notice: "Liked #{@post.user.username}'s post."
  end

  def destroy
    current_user.likes.find_by(post: @post)&.destroy
    redirect_back fallback_location: posts_path, notice: "Like removed."
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
