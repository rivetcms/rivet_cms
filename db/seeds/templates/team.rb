# Team — staff or contributor profiles for an About/Team page.
RivetCms::Seeds.template "team" do
  content_type "Team Member", slug: "team", description: "Staff and contributor profiles" do
    string :name, required: true, width: :half
    string :role, label: "Job title", width: :half
    image  :photo
    text   :bio
    string :email,    width: :half
    string :linkedin, label: "LinkedIn URL", width: :half
  end
end
