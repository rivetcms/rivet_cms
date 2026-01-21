import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "content", "title"]

  open(event) {
    event.preventDefault()
    this.drawerTarget.checked = true

    // Update title if provided
    const title = event.currentTarget.dataset.drawerTitle
    if (title && this.hasTitleTarget) {
      this.titleTarget.textContent = title
    }

    // Load content via Turbo if URL provided
    const url = event.currentTarget.dataset.url
    if (url) {
      this.loadContent(url)
    }
  }

  close() {
    this.drawerTarget.checked = false
  }

  async loadContent(url) {
    try {
      const response = await fetch(url, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      const html = await response.text()
      this.contentTarget.innerHTML = html
    } catch (error) {
      console.error("Error loading drawer content:", error)
    }
  }

  // Close on successful form submission
  handleSuccess(event) {
    if (event.detail.success) {
      this.close()
    }
  }

  // Close when clicking outside (on overlay)
  closeOnOverlay(event) {
    if (event.target.classList.contains("drawer-overlay")) {
      this.close()
    }
  }

  // Close on escape key
  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
