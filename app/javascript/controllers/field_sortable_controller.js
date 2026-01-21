import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Field sorting with drop zones for row reordering
// - Drag fields to reorder rows (drop zones appear between rows)
// - Drag half-width onto another half-width to pair them
// - Drag within paired row to swap left/right
export default class extends Controller {
  static targets = ["rowList", "row"]
  static values = {
    url: String
  }

  initialize() {
    this.rowSortables = new Map()
    this.dropZones = []
  }

  connect() {
    if (!this.hasRowListTarget) return

    // Initialize sortables for each row
    this.rowTargets.forEach(row => this.initializeRowSortable(row))
  }

  rowTargetConnected(row) {
    this.initializeRowSortable(row)
  }

  rowTargetDisconnected(row) {
    const sortable = this.rowSortables.get(row)
    if (sortable) {
      sortable.destroy()
      this.rowSortables.delete(row)
    }
  }

  initializeRowSortable(row) {
    if (this.rowSortables.has(row)) return

    const controller = this

    const sortable = new Sortable(row, {
      group: {
        name: "fields",
        put: function(to, from, dragEl) {
          // Drop zones always accept
          if (to.el.classList.contains("drop-zone")) return true
          return controller.canDropInRow(to.el, dragEl)
        }
      },
      animation: 150,
      handle: ".field-drag-handle",
      draggable: ".field-item",
      ghostClass: "sortable-ghost",
      chosenClass: "sortable-chosen",
      dragClass: "sortable-drag",
      onStart: () => this.createDropZones(),
      onEnd: (evt) => {
        this.removeDropZones()
        if (evt.from !== evt.to || evt.oldIndex !== evt.newIndex) {
          this.convertDropZonesToRows()
          this.cleanupEmptyRows()
          this.saveLayout()
        }
      }
    })

    this.rowSortables.set(row, sortable)
  }

  createDropZones() {
    this.removeDropZones()

    const rows = this.rowListTarget.querySelectorAll(".field-row")

    // Create drop zone before first row
    const firstZone = this.makeDropZone()
    this.rowListTarget.insertBefore(firstZone, rows[0])

    // Create drop zones after each row
    rows.forEach(row => {
      const zone = this.makeDropZone()
      row.after(zone)
    })
  }

  makeDropZone() {
    const zone = document.createElement("div")
    zone.className = "drop-zone field-row flex gap-2 items-stretch min-h-[3rem] border-2 border-dashed border-base-300 rounded-lg bg-base-200/30 transition-colors"
    zone.dataset.fieldSortableTarget = "row"

    // Initialize sortable for drop zone
    const controller = this
    const sortable = new Sortable(zone, {
      group: {
        name: "fields",
        put: true
      },
      animation: 150,
      ghostClass: "sortable-ghost"
    })

    this.dropZones.push({ element: zone, sortable })
    return zone
  }

  removeDropZones() {
    this.dropZones.forEach(({ element, sortable }) => {
      // Move any fields out of drop zone before removing
      const fields = element.querySelectorAll(".field-item")
      if (fields.length > 0) {
        // Convert to real row - handled in convertDropZonesToRows
        return
      }
      sortable.destroy()
      element.remove()
    })
    this.dropZones = this.dropZones.filter(({ element }) =>
      element.querySelectorAll(".field-item").length > 0
    )
  }

  convertDropZonesToRows() {
    this.dropZones.forEach(({ element, sortable }) => {
      if (element.querySelectorAll(".field-item").length > 0) {
        element.classList.remove("drop-zone", "border-dashed", "border-2", "border-base-300", "bg-base-200/30", "min-h-[3rem]")
        sortable.destroy()
        this.rowSortables.delete(element)
        this.initializeRowSortable(element)
      }
    })
    this.dropZones = []
  }

  canDropInRow(targetRow, draggedField) {
    const fieldsInTarget = targetRow.querySelectorAll(".field-item")
    const draggedWidth = draggedField.dataset.fieldWidth
    const otherFields = Array.from(fieldsInTarget).filter(f => f !== draggedField)

    // Max 2 fields per row
    if (otherFields.length >= 2) return false

    // Full-width fields must be alone
    if (otherFields.some(f => f.dataset.fieldWidth === "full")) return false

    // Can't add full-width to occupied row
    if (draggedWidth === "full" && otherFields.length > 0) return false

    // Only half-width fields can be paired
    if (otherFields.length === 1) {
      const otherField = otherFields[0]
      if (otherField.dataset.fieldWidth !== "half" || draggedWidth !== "half") return false
    }

    return true
  }

  cleanupEmptyRows() {
    this.rowListTarget.querySelectorAll(".field-row").forEach(row => {
      if (row.querySelectorAll(".field-item").length === 0) {
        const sortable = this.rowSortables.get(row)
        if (sortable) {
          sortable.destroy()
          this.rowSortables.delete(row)
        }
        row.remove()
      }
    })
  }

  disconnect() {
    this.removeDropZones()
    if (this.rowSortables) {
      this.rowSortables.forEach(sortable => sortable.destroy())
      this.rowSortables.clear()
    }
  }

  saveLayout() {
    const rows = []

    this.rowListTarget.querySelectorAll(".field-row").forEach(row => {
      const fieldIds = []
      row.querySelectorAll(".field-item").forEach(field => {
        fieldIds.push(field.dataset.fieldId)
      })
      if (fieldIds.length > 0) {
        rows.push(fieldIds)
      }
    })

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken,
        "Accept": "application/json"
      },
      body: JSON.stringify({ rows: rows })
    })
  }

  get csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
