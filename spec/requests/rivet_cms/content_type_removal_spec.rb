require 'rails_helper'
require 'rivet_cms/seeds'

module RivetCms
  RSpec.describe "Removing a content type", type: :request do
    let(:organization) { Organization.find_or_create_by!(domain: "localhost") { |o| o.name = "Test Org"; o.subdomain = "test" } }
    let(:content_type) { create(:content_type, slug: "articles", organization: organization) }

    def entry_with_content(slug)
      field = create(:field, :string, key: "title", content_type: content_type, organization: organization)
      document = create(:document, slug: slug, content_type: content_type, organization: organization)
      draft = create(:document_revision, document: document, state: :draft)
      document.update!(draft_revision: draft)
      draft.content_values.create!(field: field, string_value: "Precious")
      draft.publish!
      document
    end

    it "keeps every entry, revision, and value" do
      document = entry_with_content("keeper")
      revision_ids = document.revisions.pluck(:id)
      value_count = ContentValue.where(owner_id: revision_ids, owner_type: "RivetCms::DocumentRevision").count
      expect(value_count).to be_positive

      delete rivet_cms.content_type_path(content_type)

      expect(Document.exists?(document.id)).to be true
      expect(DocumentRevision.where(id: revision_ids).count).to eq(revision_ids.size)
      expect(ContentValue.where(owner_id: revision_ids, owner_type: "RivetCms::DocumentRevision").count).to eq(value_count)
    end

    it "hides the type from the admin but can be restored with its content" do
      entry_with_content("keeper")

      delete rivet_cms.content_type_path(content_type)

      expect(ContentType.find_by(id: content_type.id)).to be_nil
      get rivet_cms.content_types_path
      expect(response.body).not_to include("articles")

      ContentType.with_discarded.find(content_type.id).undiscard!

      get rivet_cms.content_types_path
      expect(response.body).to include("articles")
      get rivet_cms.content_type_documents_path(content_type)
      expect(response.body).to include("keeper")
    end

    it "stops serving the removed type's entries over the delivery API" do
      RivetCms.public_api = true
      entry_with_content("keeper")

      get rivet_cms.content_index_path("articles")
      expect(response).to have_http_status(:ok)

      delete rivet_cms.content_type_path(content_type)

      get rivet_cms.content_index_path("articles")
      expect(response).to have_http_status(:not_found)
      get rivet_cms.content_show_path("articles", "keeper")
      expect(response).to have_http_status(:not_found)
    end

    it "keeps entries of a removed type out of cross-type admin lists" do
      entry_with_content("keeper")

      delete rivet_cms.content_type_path(content_type)

      get rivet_cms.content_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("keeper")

      get rivet_cms.root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("keeper")
    end

    it "keeps the removed type's slug reserved so a restore cannot collide" do
      content_type
      delete rivet_cms.content_type_path(content_type)

      replacement = ContentType.new(name: "Articles", slug: "articles", organization: organization)

      expect(replacement).not_to be_valid
      expect(replacement.errors[:slug]).to be_present
    end

    describe "when another visible type references the removed one" do
      let(:authors) { create(:content_type, slug: "authors", organization: organization) }

      def article_referencing(author)
        reference = create(:field, :reference, key: "author", content_type: content_type, organization: organization)
        article = create(:document, slug: "hello", content_type: content_type, organization: organization)
        draft = create(:document_revision, document: article, state: :draft)
        article.update!(draft_revision: draft)
        draft.relations.create!(field: reference, target_document: author, position: 0)
        draft.publish!
        article
      end

      def published_author
        author = create(:document, slug: "jane", content_type: authors, organization: organization)
        draft = create(:document_revision, document: author, state: :draft)
        author.update!(draft_revision: draft)
        draft.publish!
        author
      end

      before { RivetCms.public_api = true }

      it "still serves the referencing type and omits the hidden target" do
        article_referencing(published_author)
        delete rivet_cms.content_type_path(authors)

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "author" }
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("jane")

        get rivet_cms.content_index_path("articles"), params: { populate: "author" }
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("jane")
      end

      it "omits the hidden target from the Ruby helpers too" do
        article_referencing(published_author)
        delete rivet_cms.content_type_path(authors)

        entry = RivetCms.entry("articles", "hello", organization: organization, populate: [ "author" ])

        expect(entry).to be_present
        expect(entry.to_h.to_s).not_to include("jane")
      end

      it "restores the reference when the type comes back" do
        article_referencing(published_author)
        delete rivet_cms.content_type_path(authors)
        ContentType.with_discarded.find(authors.id).undiscard!

        get rivet_cms.content_show_path("articles", "hello"), params: { populate: "author" }

        expect(response.body).to include("jane")
      end
    end

    it "re-seeding a template neither collides with nor resurrects a removed type" do
      RivetCms::Seeds.load!(organization: organization, only: [ "blog" ])
      posts = ContentType.find_by(slug: "posts")
      posts.discard!

      # Rename it so we can prove seeding leaves the removed row alone
      posts.update_columns(name: "Renamed By Operator")

      expect { RivetCms::Seeds.load!(organization: organization, only: [ "blog" ]) }.not_to raise_error

      expect(ContentType.find_by(slug: "posts")).to be_nil
      still_removed = ContentType.with_discarded.find_by(slug: "posts")
      expect(still_removed).to be_present
      expect(still_removed.name).to eq("Renamed By Operator")
    end

    it "re-seeding does not rewrite a removed type's schema" do
      RivetCms::Seeds.load!(organization: organization, only: [ "blog" ])
      posts = ContentType.find_by(slug: "posts")
      field = posts.fields.kept.first
      field.discard
      posts.discard!
      field_ids = Field.with_discarded.where(content_type_id: posts.id).pluck(:id).sort

      RivetCms::Seeds.load!(organization: organization, only: [ "blog" ])

      expect(field.reload.deleted_at).to be_present # not resurrected
      expect(Field.with_discarded.where(content_type_id: posts.id).pluck(:id).sort).to eq(field_ids)
    end

    it "re-seeds the rest of a template when a referenced type is removed" do
      RivetCms::Seeds.load!(organization: organization, only: [ "blog" ])
      authors = ContentType.find_by(slug: "authors")
      posts = ContentType.find_by(slug: "posts")
      authors.discard!

      expect { RivetCms::Seeds.load!(organization: organization, only: [ "blog" ]) }.not_to raise_error

      # The rest of the template still seeds, and the existing reference field
      # is left as it was so restoring the type makes it work again.
      expect(ContentType.find_by(slug: "posts")).to be_present
      reference = posts.reload.fields.kept.find_by(field_type: "reference")
      expect(reference.config["content_type_id"]).to eq(authors.id)
    end

    it "does not seed a new reference field pointing at a removed type" do
      RivetCms::Seeds.load!(organization: organization, only: [ "blog" ])
      authors = ContentType.find_by(slug: "authors")
      posts = ContentType.find_by(slug: "posts")
      posts.fields.with_discarded.where(field_type: "reference").find_each(&:destroy)
      authors.discard!

      RivetCms::Seeds.load!(organization: organization, only: [ "blog" ])

      targets = posts.reload.fields.with_discarded.where(field_type: "reference").map { |f| f.config["content_type_id"] }
      expect(targets).not_to include(authors.id)
    end

    it "seeds every template even when one names a removed type" do
      RivetCms::Seeds.load!(organization: organization)
      ContentType.find_by(slug: "authors").discard!
      ContentType.find_by(slug: "events")&.destroy

      expect { RivetCms::Seeds.load!(organization: organization) }.not_to raise_error
      expect(ContentType.find_by(slug: "events")).to be_present
    end

    it "renaming an existing type onto a removed slug explains why" do
      other = create(:content_type, slug: "notes", organization: organization)
      delete rivet_cms.content_type_path(content_type)

      other.slug = "articles"

      expect(other).not_to be_valid
      expect(other.errors[:slug]).to eq([ "belongs to a removed content type; restore that type instead of recreating it" ])
    end

    it "names the removed type in the webhook payload" do
      document = entry_with_content("keeper")
      revision = document.reload.published_revision
      delete rivet_cms.content_type_path(content_type)

      payload = Webhooks.payload(:publish, revision.reload)

      expect(payload[:content_type]).to eq("articles")
    end

    it "refuses to publish or edit an entry whose type was removed" do
      document = entry_with_content("keeper")
      delete rivet_cms.content_type_path(content_type)
      draft = document.reload.draft_revision

      expect { draft.publish! }.to raise_error(RemovedContentTypeError, /before publishing/)
      expect { DraftWriter.new(draft).write({}) }.to raise_error(RemovedContentTypeError, /before editing/)
      expect { ContentValidator.new(draft).validate }.to raise_error(RemovedContentTypeError, /before validating/)
    end

    it "destroys an organization whose entries reference each other" do
      other_type = create(:content_type, slug: "authors", organization: organization)
      target = create(:document, slug: "jane", content_type: other_type, organization: organization)
      reference = create(:field, :reference, key: "author", content_type: content_type, organization: organization)
      article = create(:document, slug: "hello", content_type: content_type, organization: organization)
      draft = create(:document_revision, document: article, state: :draft)
      article.update!(draft_revision: draft)
      draft.relations.create!(field: reference, target_document: target, position: 0)
      org_id = organization.id

      expect { organization.reload.destroy }.not_to raise_error
      expect(Organization.exists?(org_id)).to be false
      expect(Relation.where(target_document_id: target.id)).to be_empty
    end

    it "destroying an organization clears removed types and their content" do
      entry_with_content("keeper")
      delete rivet_cms.content_type_path(content_type)
      org_id = organization.id

      expect(organization.reload.destroy).to be_truthy
      expect(Organization.exists?(org_id)).to be false
      expect(ContentType.with_discarded.where(organization_id: org_id)).to be_empty
      expect(Document.where(content_type_id: content_type.id)).to be_empty
    end

    it "says why when content blocks destroying an organization" do
      entry_with_content("keeper")
      allow_any_instance_of(Document).to receive(:destroy!).and_raise(
        ActiveRecord::RecordNotDestroyed.new("Failed to destroy", Document.new)
      )

      expect(organization.reload.destroy).to be false
      expect(organization.errors[:base].join).to include("could not remove content")
    end

    it "explains that a removed type is holding the slug" do
      content_type
      delete rivet_cms.content_type_path(content_type)

      replacement = ContentType.new(name: "Articles", slug: "articles", organization: organization)
      replacement.valid?

      expect(replacement.errors[:slug]).to eq([ "belongs to a removed content type; restore that type instead of recreating it" ])
    end

    it "refuses a hard destroy while entries exist" do
      document = entry_with_content("keeper")

      expect(ContentType.with_discarded.find(content_type.id).destroy).to be false
      expect(Document.exists?(document.id)).to be true
    end
  end
end
