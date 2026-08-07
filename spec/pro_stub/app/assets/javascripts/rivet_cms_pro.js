// The Pro stub's admin bundle. Request specs have no JS runtime, so this is
// never executed by the suite; it exists so asset tags resolve and to
// document what a real extension bundle does: register pages and slot
// components on the shared global before the admin app boots, using the
// exposed React instance.
const { React } = window.RivetCMS

window.RivetCMS.registerPages({
  "ProStub/Panel": function ProStubPanel(props) {
    return React.createElement("div", null, props.message)
  },
})

// Slot components mount inside core pages and receive that page's props;
// entry.* slots get { document, contentType }.
window.RivetCMS.registerSlot("entry.actions", function ScheduleStub(props) {
  return React.createElement("button", { type: "button", className: "btn btn-ghost" }, "Schedule")
})
