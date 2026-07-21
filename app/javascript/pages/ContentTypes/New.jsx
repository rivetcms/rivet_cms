import ContentTypeForm from "../../components/ContentTypeForm"

export default function New() {
  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-xl font-semibold mb-8">New Content Type</h1>
      <ContentTypeForm submitLabel="Create Content type" />
    </div>
  )
}
