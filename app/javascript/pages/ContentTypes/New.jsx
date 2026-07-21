import PageHeader from "../../components/PageHeader"
import ContentTypeForm from "../../components/ContentTypeForm"

export default function New() {
  return (
    <div className="mx-auto max-w-2xl">
      <PageHeader title="New Content Type" description="Create a structure for a new kind of content." />
      <div className="rounded-box border border-base-300 bg-base-100 p-6">
        <ContentTypeForm submitLabel="Create Content Type" />
      </div>
    </div>
  )
}
