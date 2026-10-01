module ApplicationHelper
  # Marks the nav item matching the current page so it can be styled.
  def nav_link_to(label, path)
    link_to label, path, class: "nav-link #{'active' if current_page?(path)}"
  end

  # Reads better than the raw "about 5 minutes" in dense feeds.
  def short_time_ago(time)
    "#{time_ago_in_words(time)} ago"
  end
end
