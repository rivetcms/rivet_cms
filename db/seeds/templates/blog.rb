# Blog — the classic starting point. Posts are backed by the authors and
# categories they relate to, plus a reusable SEO component.
RivetCms::Seeds.template "blog" do
  category "Content", system: true

  component "SEO", category: "Content", slug: "seo", description: "Search-engine and social sharing metadata" do
    string  :meta_title,       width: :half
    string  :meta_description, width: :half
    image   :og_image,         label: "Social share image"
    boolean :no_index,         label: "Hide from search engines"
  end

  content_type "Author", slug: "authors", description: "People who write your content" do
    string    :name,    required: true, width: :half
    string    :email,   width: :half, config: { "pattern" => "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$" }
    image     :avatar
    rich_text :bio
    string    :x_handle, label: "X (Twitter)", width: :half
    string    :website,  width: :half
  end

  content_type "Category", slug: "categories", description: "Topics used to group posts" do
    string :name,  required: true, width: :half
    string :color, label: "Color (hex)", width: :half
    text   :description
  end

  content_type "Blog Post", slug: "posts", description: "Articles and news for your blog" do
    string    :title, required: true
    text      :excerpt, description: "Short summary shown in listings and link previews"
    image     :cover_image
    rich_text :body, required: true
    reference :author,     to: "authors",    max_items: 1
    reference :categories, to: "categories"
    datetime  :published_at, width: :half
    boolean   :featured,     label: "Feature this post", width: :half
    component :seo, use: "SEO", max_items: 1
  end
end
