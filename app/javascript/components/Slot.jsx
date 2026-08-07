import { Component as ReactComponent } from "react"
import { slotComponents } from "../lib/slots"

// A broken extension component logs and renders nothing rather than taking
// the page down, matching the fail-open posture of extension asset tags.
class SlotBoundary extends ReactComponent {
  constructor(props) {
    super(props)
    this.state = { failed: false }
  }

  static getDerivedStateFromError() {
    return { failed: true }
  }

  componentDidCatch(error) {
    console.error(`[RivetCMS] slot "${this.props.name}" component failed:`, error)
  }

  render() {
    return this.state.failed ? null : this.props.children
  }
}

export default function Slot({ name, ...props }) {
  const components = slotComponents(name)
  if (components.length === 0) return null

  return components.map((SlotComponent, index) => (
    <SlotBoundary key={index} name={name}>
      <SlotComponent {...props} />
    </SlotBoundary>
  ))
}
