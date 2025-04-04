import { Controller } from "@hotwired/stimulus"
import pluralize from "pluralize"

export default class extends Controller {
  static targets = ["name", "slug", "isSingle"]

  connect() {
    this.nameTarget.addEventListener("input", this.updateSlug.bind(this))
    this.isSingleTarget.addEventListener("change", this.updateSlug.bind(this))
    this.lastGeneratedSlug = this.slugTarget.value
  }

  updateSlug() {
    const name = this.nameTarget.value.trim()
    if (!name) {
      this.slugTarget.value = ""
      return
    }

    let slug = this.generateSlug(name)
    if (!slug) {
      this.slugTarget.value = ""
      return
    }

    const isSingle = this.isSingleTarget.checked
    if (isSingle && pluralize.isPlural(slug)) {
      slug = pluralize.singular(slug)
    } else if (!isSingle && !pluralize.isPlural(slug)) {
      slug = pluralize(slug)
    }

    if (slug !== this.lastGeneratedSlug) {
      this.slugTarget.value = slug
      this.lastGeneratedSlug = slug
    }
  }

  generateSlug(text) {
    return text
      .toLowerCase()
      .replace(/[\s_]+/g, "-")      // Spaces or underscores to hyphen
      .replace(/[^a-z0-9-]/g, "")   // Keep letters, numbers, hyphens
      .replace(/-+/g, "-")          // Collapse hyphens
      .replace(/^-|-$/g, "")        // Trim leading/trailing hyphens
      .trim()
  }

  disconnect() {
    this.nameTarget.removeEventListener("input", this.updateSlug.bind(this))
    this.isSingleTarget.removeEventListener("change", this.updateSlug.bind(this))
  }
}