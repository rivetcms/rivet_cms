// Extension seam: named mount points inside core pages. Bundles register
// components before the app boots, the same way they register pages; a slot
// nobody registered into renders nothing.
const registry = {}

export function registerSlot(name, component) {
  ;(registry[name] ||= []).push(component)
}

export function slotComponents(name) {
  return registry[name] || []
}
