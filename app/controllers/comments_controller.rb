class CommentsController < ApplicationController
  before_action :set_post, only: :create

  def create
    comment = @post.comments.build(comment_params.merge(user: current_user))

    if comment.save
      redirect_back fallback_location: posts_path, notice: "Comment added."
    else
      redirect_back fallback_location: posts_path,
        alert: comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    comment = current_user.comments.find(params[:id])
    comment.destroy!
    redirect_back fallback_location: posts_path,
      notice: "Comment deleted.", status: :see_other
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
