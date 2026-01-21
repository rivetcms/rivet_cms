import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "listbox", "hidden"]
  static values = {
    createUrl: String
  }

  connect() {
    // Listen for option clicks, especially the "Create category" option
    this.listboxTarget.addEventListener("click", this.handleOptionClick.bind(this))
    
    // Listen for when Basecoat updates the hidden input
    this.hiddenTarget.addEventListener("change", this.handleValueChange.bind(this))
    
    // Also listen for input events to catch Basecoat updates
    this.hiddenTarget.addEventListener("input", this.handleValueChange.bind(this))
  }

  handleOptionClick(event) {
    const option = event.target.closest('[role="option"]')
    if (!option) return

    const isCreate = option.hasAttribute("data-create")
    if (isCreate) {
      event.preventDefault()
      event.stopPropagation()
      this.createCategory()
    }
  }

  async createCategory() {
    const searchInput = this.element.querySelector('input[role="combobox"]')
    const categoryName = searchInput?.value.trim()
    
    if (!categoryName) {
      alert("Please enter a category name")
      return
    }

    if (!this.createUrlValue) {
      console.error("No create URL provided")
      return
    }

    try {
      const response = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ category: { name: categoryName } })
      })

      if (response.ok) {
        const data = await response.json()
        
        // Add the new category to the listbox
        const separator = this.listboxTarget.querySelector('hr[role="separator"]')
        const newOption = document.createElement("div")
        newOption.setAttribute("role", "option")
        newOption.setAttribute("data-value", data.id)
        newOption.textContent = data.name
        
        if (separator) {
          separator.before(newOption)
        } else {
          this.listboxTarget.insertBefore(newOption, this.listboxTarget.querySelector('[data-create]'))
        }
        
        // Select the newly created category
        newOption.click()
      } else {
        const error = await response.json()
        alert(error.errors?.join(", ") || "Failed to create category")
      }
    } catch (error) {
      console.error("Error creating category:", error)
      alert("Error creating category")
    }
  }

  handleValueChange() {
    // Sync Basecoat's hidden input value to Rails form field
    const railsField = document.getElementById("component_category_id")
    if (railsField && this.hiddenTarget.value) {
      railsField.value = this.hiddenTarget.value
    }
  }
}

