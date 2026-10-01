class PostsController < ApplicationController
  def index
    @post = Post.new
    @posts = Post.from_feed_of(current_user)
      .includes(:user, { comments: :user }, :likes)
  end

  # "For You": recent posts from everyone except the current user, so you can
  # discover people you don't already follow.
  def discover
    @posts = Post.from_discover_for(current_user)
      .includes(:user, { comments: :user }, :likes)
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to posts_path, notice: "Post created."
    else
      @posts = Post.from_feed_of(current_user)
        .includes(:user, { comments: :user }, :likes)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    post = current_user.posts.find(params[:id])
    post.destroy!
    redirect_to posts_path, notice: "Post deleted.", status: :see_other
  end

  private

  def post_params
    params.require(:post).permit(:content)
  end
end
