require "rails_helper"

module RivetCms
  RSpec.describe "RivetCms content helpers" do
    let(:organization) { create(:organization) }
    let(:posts) { create(:content_type, slug: "posts", organization: organization) }
    let(:authors) { create(:content_type, slug: "authors", organization: organization) }
    let!(:title_field) { create(:field, :string, key: "title", content_type: posts, organization: organization) }
    let!(:author_field) do
      create(:field, field_type: :reference, key: "author", max_items: 1, content_type: posts, organization: organization)
    end
    let!(:name_field) { create(:field, :string, key: "name", content_type: authors, organization: organization) }

    def publish(content_type, slug:, values: {}, relations: {})
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      values.each { |field, value| draft.content_values.create!(field: field, string_value: value) }
      relations.each do |field, targets|
        Array(targets).each_with_index { |target, i| draft.relations.create!(field: field, target_document: target, position: i) }
      end
      draft.publish!
      document
    end

    describe ".entries" do
      it "returns published entries with pagination accessors" do
        3.times { |i| publish(posts, slug: "p#{i}", values: { title_field => "Post #{i}" }) }
        create(:document, slug: "draft-only", content_type: posts, organization: organization)

        list = RivetCms.entries("posts", organization: organization, per_page: 2)

        expect(list).to be_a(EntryCollection)
        expect(list.size).to eq(2)
        expect(list.total).to eq(3)
        expect(list.total_pages).to eq(2)
        expect(list.map(&:slug)).not_to include("draft-only")
        expect(list.first.title).to start_with("Post")
      end

      it "sorts by an integer field key" do
        order_field = create(:field, field_type: :integer, key: "nav_order", content_type: posts, organization: organization)
        [ [ "second", 2 ], [ "first", 1 ] ].each do |slug, value|
          document = publish(posts, slug: slug)
          document.published_revision.content_values.create!(field: order_field, integer_value: value)
        end

        expect(RivetCms.entries("posts", organization: organization, sort: "nav_order").map(&:slug)).to eq(%w[first second])
        expect(RivetCms.entries("posts", organization: organization, sort: "-nav_order").map(&:slug)).to eq(%w[second first])
      end

      it "populates references into nested entries" do
        jane = publish(authors, slug: "jane", values: { name_field => "Jane" })
        publish(posts, slug: "hello", values: { title_field => "Hi" }, relations: { author_field => jane })

        post = RivetCms.entries("posts", organization: organization, populate: :all).first

        expect(post.author).to be_a(Entry)
        expect(post.author.name).to eq("Jane")
      end

      it "keeps references shallow without populate and omits draft-only targets" do
        hidden = create(:document, slug: "hidden", content_type: authors, organization: organization)
        hidden_draft = create(:document_revision, document: hidden, state: :draft)
        hidden.update!(draft_revision: hidden_draft)
        publish(posts, slug: "hello", values: { title_field => "Hi" }, relations: { author_field => hidden })

        post = RivetCms.entries("posts", organization: organization).first
        expect(post.author).to be_nil
      end

      it "selects sparse fields" do
        publish(posts, slug: "hello", values: { title_field => "Hi" })

        post = RivetCms.entries("posts", organization: organization, fields: [ "title" ]).first
        expect(post.data.keys).to eq([ "title" ])
      end

      it "raises for an unknown content type" do
        expect { RivetCms.entries("nope", organization: organization) }
          .to raise_error(ContentQuery::Error, /unknown content type/)
      end
    end

    describe ".entry" do
      it "finds by slug and returns nil when missing or unpublished" do
        publish(posts, slug: "hello", values: { title_field => "Hi" })
        create(:document, slug: "wip", content_type: posts, organization: organization)

        expect(RivetCms.entry("posts", "hello", organization: organization).title).to eq("Hi")
        expect(RivetCms.entry("posts", "missing", organization: organization)).to be_nil
        expect(RivetCms.entry("posts", "wip", organization: organization)).to be_nil
      end

      it "serves the draft with preview: true" do
        document = publish(posts, slug: "hello", values: { title_field => "V1" })
        new_draft = create(:document_revision, document: document, state: :draft)
        document.update!(draft_revision: new_draft)
        new_draft.content_values.create!(field: title_field, string_value: "V2 draft")

        expect(RivetCms.entry("posts", "hello", organization: organization).title).to eq("V1")
        expect(RivetCms.entry("posts", "hello", organization: organization, preview: true).title).to eq("V2 draft")
      end
    end

    describe ".single" do
      it "returns the singleton entry" do
        settings = create(:content_type, slug: "site-settings", single: true, organization: organization)
        site_name = create(:field, :string, key: "site_name", content_type: settings, organization: organization)
        publish(settings, slug: "settings", values: { site_name => "My Site" })

        expect(RivetCms.single("site-settings", organization: organization).site_name).to eq("My Site")
      end
    end

    describe "organization resolution" do
      it "falls back to Current.organization" do
        publish(posts, slug: "hello", values: { title_field => "Hi" })
        RivetCms::Current.set(organization: organization) do
          expect(RivetCms.entries("posts").total).to eq(1)
        end
      end

      it "scopes to the given organization only" do
        other = create(:organization)
        create(:content_type, slug: "posts", organization: other)
        publish(posts, slug: "hello", values: { title_field => "Hi" })

        expect(RivetCms.entries("posts", organization: other).total).to eq(0)
      end
    end

    describe Entry do
      it "exposes data via methods, [] and to_h, and reports published state" do
        publish(posts, slug: "hello", values: { title_field => "Hi" })
        post = RivetCms.entry("posts", "hello", organization: organization)

        expect(post.title).to eq("Hi")
        expect(post[:title]).to eq("Hi")
        expect(post["title"]).to eq("Hi")
        expect(post.to_h[:data]["title"]).to eq("Hi")
        expect(post).to be_published
        expect(post.respond_to?(:title)).to be(true)
        expect { post.nonexistent_key }.to raise_error(NoMethodError)
      end
    end
  end
end
