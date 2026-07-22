require 'rails_helper'

module RivetCms
  RSpec.describe RevisionSerializer do
    it "keeps allowed rich-text tags and strips disallowed ones" do
      document = create(:document)
      field = create(:field, field_type: :rich_text, key: "body",
                             content_type: document.content_type, organization: document.organization)
      revision = create(:document_revision, document: document, state: :published)
      revision.content_values.create!(
        field: field,
        text_value: '<p style="text-align:center;background:url(javascript:alert(1))"><strong>Hi</strong> <u>u</u> <s>s</s> ' \
                    '<a href="/x" target="_blank" rel="noopener" title="t">l</a> ' \
                    '<img src="/i.png" alt="a" width="120" height="80" style="float:left"></p>' \
                    '<hr><script>alert(1)</script>'
      )

      body = described_class.new(revision).as_json[:data]["body"]

      expect(body).to include("<strong>", "<u>", "<s>", "<a", "<hr", 'target="_blank"', 'rel="noopener"', 'width="120"', 'height="80"')
      expect(body).to include("text-align", "float")
      expect(body).not_to include("<script>")
      expect(body).not_to include("javascript")
    end
  end
end
