import { Controller } from "@hotwired/stimulus"
import pluralize from "pluralize"

export default class extends Controller {
  static targets = ["name", "slug", "single"]

  connect() {
    this.nameTarget.addEventListener("input", this.updateSlug.bind(this))
    this.singleTarget.addEventListener("change", this.updateSlug.bind(this))
    this.slugTarget.addEventListener("input", this.cleanSlug.bind(this))
  }

  updateSlug() {
    const name = this.nameTarget.value.trim()
    if (!name) return

    let slug = this.generateSlug(name)

    if (name.length < 3 ) {
      return this.slugTarget.value = ''
    }

    if (!slug) return

    const isSingle = this.singleTarget.checked

    // Use pluralize lib instead of custom rules
    if (isSingle) {
      slug = pluralize.singular(slug)
    } else {
      slug = pluralize(slug)
    }

    // Final cleanup of allowed characters
    slug = slug.replace(/[^a-z\-]/g, '')

    if (slug) {
      this.slugTarget.value = slug
    }
  }

  cleanSlug(event) {
    // Clean up slug input directly as user types
    const input = event.target
    const cursorPosition = input.selectionStart
    const originalValue = input.value
    
    // Convert to lowercase, replace spaces/underscores with hyphens
    let value = originalValue
      .toLowerCase()
      .replace(/\s+/g, '-')        // spaces → hyphens
      .replace(/_+/g, '-')         // underscores → hyphens
      .replace(/[^a-z\-]/g, '')   // remove everything except a-z and hyphens
      .replace(/\-\-+/g, '-')      // collapse "--" to "-"
    
    // Don't trim hyphens from start/end while typing - allow user to type hyphens
    // The trimming will happen on blur or when auto-generating from name
    
    // Update the input value
    input.value = value
    
    // Calculate new cursor position
    // Simple approach: count valid characters before cursor in original value
    const beforeCursor = originalValue.substring(0, cursorPosition).toLowerCase()
    const cleanedBeforeCursor = beforeCursor
      .replace(/\s+/g, '-')
      .replace(/_+/g, '-')
      .replace(/[^a-z\-]/g, '')
      .replace(/\-\-+/g, '-')
    
    const newPosition = cleanedBeforeCursor.length
    input.setSelectionRange(newPosition, newPosition)
  }

  generateSlug(text) {
    return text
      .toLowerCase()
      .replace(/\s+/g, '-')        // spaces → hyphens
      .replace(/_+/g, '-')         // underscores → hyphens
      .replace(/[^\w\-]+/g, '')    // remove non-word chars
      .replace(/\d+/g, '')         // remove numbers
      .replace(/\-\-+/g, '-')      // collapse "--" to "-"
      .replace(/^-+/, '')          // trim start hyphens
      .replace(/-+$/, '')          // trim end hyphens
  }
}
