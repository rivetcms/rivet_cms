import PageHeader from "../../components/PageHeader"
import ContentTypeForm from "../../components/ContentTypeForm"

export default function Edit({ content_type: contentType }) {
  return (
    <div className="mx-auto max-w-2xl">
      <PageHeader title={`Edit ${contentType.name}`} description="Update this content type's settings." />
      <div className="rounded-box border border-base-300 bg-base-100 p-6">
        <ContentTypeForm contentType={contentType} submitLabel="Save Changes" />
      </div>
    </div>
  )
}
