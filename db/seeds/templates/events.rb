# Events — scheduled happenings. Showcases the date/datetime field types.
RivetCms::Seeds.template "events" do
  content_type "Event", slug: "events", description: "Scheduled events, conferences, and webinars" do
    string    :title, required: true
    rich_text :description
    datetime  :starts_at, required: true, width: :half
    datetime  :ends_at, width: :half
    string    :location, description: "Venue or a link for online events"
    string    :registration_url, label: "Registration URL"
    image     :cover_image
  end
end
