// The Pro stub's admin bundle. Request specs have no JS runtime, so this is
// never executed by the suite; it exists so asset tags resolve and to
// document what a real extension bundle does: register pages on the shared
// global before the admin app boots, using the exposed React instance.
const { React } = window.RivetCMS
window.RivetCMS.registerPages({
  "ProStub/Panel": function ProStubPanel(props) {
    return React.createElement("div", null, props.message)
  },
})
