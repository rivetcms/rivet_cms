import ContentTypeForm from "../../components/ContentTypeForm"

export default function Edit({ content_type: contentType }) {
  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-xl font-semibold mb-8">Edit {contentType.name}</h1>
      <ContentTypeForm contentType={contentType} submitLabel="Update Content type" />
    </div>
  )
}
