import { Controller } from "@hotwired/stimulus"

/**
 * Field Layout Controller
 * 
 * Manages the drag-and-drop functionality for field layout in the content editor.
 * Allows for reordering fields, placing them side by side, and adjusting their width.
 */
export default class extends Controller {
  static targets = ["field"]
  static values = {
    contentTypeId: String,
    updatePositionsPath: String
  }

  // Configuration constants
  static config = {
    dragDetection: {
      extendedLeft: 200,      // Extended detection area to the left (px)
      priorityFactor: 0.1,    // Factor to prioritize fields in drag direction
      verticalThreshold: 30   // Threshold for vertical distance detection (px)
    },
    styling: {
      gap: "0.75rem",
      padding: "0.75rem",
      ghostOpacity: "0.7",
      ghostScale: "1.02"
    }
  }

  /**
   * Initialize the controller when connected to the DOM
   */
  connect() {
    this.handleDragMove = this.handleDragMove.bind(this);
    this.handleDragEnd = this.handleDragEnd.bind(this);
    this.setupGridLayout();
    this.applyBaseStyles();
    this.initializeDragAndDrop();
    this.updateLayout();
  }

  /**
   * Set up the initial grid layout
   */
  setupGridLayout() {
    this.element.style.display = "grid";
    this.element.style.gridTemplateColumns = "1fr 1fr";
    this.element.style.gap = this.constructor.config.styling.gap;
  }

  /**
   * Apply base styles to all field elements
   */
  applyBaseStyles() {
    this.fieldTargets.forEach(field => {
      field.classList.add(
        'bg-gray-50', 
        'hover:bg-gray-100',
        'dark:bg-neutral-950',
        'dark:hover:bg-neutral-900',
        'rounded-lg', 
        'transition-colors'
      );
    });
  }

  /**
   * Initialize drag and drop functionality
   */
  initializeDragAndDrop() {
    // Initialize drag state
    this.resetDragState();
    
    // Add event listeners to drag handles
    this.fieldTargets.forEach(field => {
      const handle = field.querySelector('.cursor-move');
      if (!handle) return;
      
      handle.addEventListener('mousedown', (e) => {
        e.preventDefault();
        this.startDragging(field, e);
      });
    });
  }
  
  /**
   * Reset all drag-related state variables
   */
  resetDragState() {
    this.draggedField = null;
    this.dragStartY = 0;
    this.dragStartX = 0;
    this.ghostElement = null;
    this.dropTarget = null;
    this.dropPosition = null;
    this.dropZone = null;
    this.originalTop = 0;
    this.originalLeft = 0;
  }
  
  /**
   * Start dragging a field
   * @param {HTMLElement} field - The field element being dragged
   * @param {MouseEvent} event - The mousedown event
   */
  startDragging(field, event) {
    this.draggedField = field;
    this.dragStartY = event.clientY;
    this.dragStartX = event.clientX;
    
    // Store original position
    const rect = field.getBoundingClientRect();
    this.originalTop = rect.top;
    this.originalLeft = rect.left;
    
    // Create and position ghost element
    this.createGhostElement(field, rect);
    
    // Hide original field
    field.style.opacity = '0';
    
    // Add event listeners for drag operations
    document.addEventListener('mousemove', this.handleDragMove);
    document.addEventListener('mouseup', this.handleDragEnd);
  }

  /**
   * Create a ghost element for dragging
   * @param {HTMLElement} field - The field being dragged
   * @param {DOMRect} rect - The bounding rectangle of the field
   */
  createGhostElement(field, rect) {
    const { ghostOpacity, ghostScale } = this.constructor.config.styling;
    
    this.ghostElement = field.cloneNode(true);
    this.ghostElement.style.position = 'fixed';
    this.ghostElement.style.top = `${rect.top}px`;
    this.ghostElement.style.left = `${rect.left}px`;
    this.ghostElement.style.width = `${rect.width}px`;
    this.ghostElement.style.opacity = ghostOpacity;
    this.ghostElement.style.pointerEvents = 'none';
    this.ghostElement.style.zIndex = '1000';
    this.ghostElement.style.transform = `scale(${ghostScale})`;
    this.ghostElement.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
    
    document.body.appendChild(this.ghostElement);
  }
  
  /**
   * Handle mouse movement during drag
   * @param {MouseEvent} event - The mousemove event
   */
  handleDragMove = (event) => {
    if (!this.draggedField || !this.ghostElement) return;
    
    // Move ghost element
    this.moveGhostElement(event);
    
    // Clear existing indicators
    this.clearDropIndicators();
    
    // Find closest field and show drop indicator
    const closestField = this.findClosestField(event);
    if (!closestField) return;
    
    this.showDropIndicator(closestField, event);
  }
  
  /**
   * Move the ghost element with the mouse
   * @param {MouseEvent} event - The mousemove event
   */
  moveGhostElement(event) {
    const deltaX = event.clientX - this.dragStartX;
    const deltaY = event.clientY - this.dragStartY;
    const { ghostScale } = this.constructor.config.styling;
    
    this.ghostElement.style.transform = `translate(${deltaX}px, ${deltaY}px) scale(${ghostScale})`;
  }
  
  /**
   * Clear all drop indicators
   */
  clearDropIndicators() {
    this.fieldTargets.forEach(field => {
      field.classList.remove('bg-gray-100', 'dark:bg-neutral-800', 'dark:bg-neutral-700');
      const dropZone = field.querySelector('.drop-indicator');
      if (dropZone) dropZone.remove();
    });
  }
  
  /**
   * Find the closest field to the current mouse position
   * @param {MouseEvent} event - The mousemove event
   * @returns {HTMLElement|null} - The closest field or null if none found
   */
  findClosestField(event) {
    const mouseX = event.clientX;
    const mouseY = event.clientY;
    let closestField = null;
    let minDistance = Infinity;
    
    const { extendedLeft, priorityFactor } = this.constructor.config.dragDetection;
    
    this.fieldTargets.forEach(field => {
      if (field === this.draggedField) return;
      
      const rect = field.getBoundingClientRect();
      const extendedRect = {
        top: rect.top - 8,
        bottom: rect.bottom + 8,
        left: rect.left - extendedLeft,
        right: rect.right + 8,
        width: rect.width + extendedLeft + 8,
        height: rect.height + 16
      };
      
      if (mouseX >= extendedRect.left && mouseX <= extendedRect.right &&
          mouseY >= extendedRect.top && mouseY <= extendedRect.bottom) {
        
        // Determine if we're dragging left-to-right
        const isLeftToRight = this.originalLeft < rect.left;
        
        // For left-to-right dragging, prioritize fields to the right
        let distance = Math.abs(mouseY - (rect.top + rect.height / 2));
        
        if (isLeftToRight && rect.left > this.originalLeft) {
          // This is a field to the right of the dragged field
          // Give it a much lower distance to prioritize it
          distance = distance * priorityFactor;
        }
        
        if (distance < minDistance) {
          minDistance = distance;
          closestField = field;
        }
      }
    });
    
    return closestField;
  }
  
  /**
   * Show the appropriate drop indicator based on field and mouse position
   * @param {HTMLElement} closestField - The closest field to drop on
   * @param {MouseEvent} event - The mousemove event
   */
  showDropIndicator(closestField, event) {
    const rect = closestField.getBoundingClientRect();
    const mouseX = event.clientX;
    const mouseY = event.clientY;
    const isHalfWidth = closestField.dataset.width === "half" && this.draggedField.dataset.width === "half";
    
    // Handle paired fields (full width field over half width field)
    if (this.handlePairedFieldsIndicator(closestField, mouseY)) {
      return;
    }
    
    // Handle horizontal indicators for half-width fields
    if (isHalfWidth && this.handleHorizontalIndicator(closestField, rect, mouseX, mouseY)) {
      return;
    }
    
    // Handle vertical indicators (default case)
    this.handleVerticalIndicator(closestField, rect, mouseY);
  }
  
  /**
   * Handle drop indicators for paired fields
   * @param {HTMLElement} closestField - The closest field
   * @param {number} mouseY - The mouse Y position
   * @returns {boolean} - True if handled, false otherwise
   */
  handlePairedFieldsIndicator(closestField, mouseY) {
    if (this.draggedField.dataset.width === "full" && 
        closestField.dataset.width === "half" && 
        closestField.dataset.rowGroup) {
      
      const pairedField = this.fieldTargets.find(f => 
        f !== closestField && 
        f.dataset.rowGroup === closestField.dataset.rowGroup
      );
      
      if (pairedField) {
        const closestRect = closestField.getBoundingClientRect();
        const pairedRect = pairedField.getBoundingClientRect();
        
        const rowRect = {
          top: Math.min(closestRect.top, pairedRect.top),
          bottom: Math.max(closestRect.bottom, pairedRect.bottom),
          height: Math.max(closestRect.bottom, pairedRect.bottom) - 
                  Math.min(closestRect.top, pairedRect.top)
        };
        
        const dropZone = document.createElement('div');
        dropZone.className = 'drop-indicator absolute left-0 right-0 bg-gray-500 dark:bg-gray-400 transition-all duration-200';
        dropZone.style.height = '2px';
        
        const rowCenterY = rowRect.top + (rowRect.height / 2);
        if (mouseY < rowCenterY) {
          dropZone.style.top = '0';
          this.dropPosition = 'above';
        } else {
          dropZone.style.bottom = '0';
          this.dropPosition = 'below';
        }
        
        closestField.classList.add('bg-gray-100', 'dark:bg-neutral-700');
        pairedField.classList.add('bg-gray-100', 'dark:bg-neutral-700');
        closestField.appendChild(dropZone);
        this.dropTarget = closestField;
        return true;
      }
    }
    
    return false;
  }
  
  /**
   * Handle horizontal drop indicators for half-width fields
   * @param {HTMLElement} closestField - The closest field
   * @param {DOMRect} rect - The bounding rectangle of the closest field
   * @param {number} mouseX - The mouse X position
   * @param {number} mouseY - The mouse Y position
   * @returns {boolean} - True if handled, false otherwise
   */
  handleHorizontalIndicator(closestField, rect, mouseX, mouseY) {
    const { verticalThreshold } = this.constructor.config.dragDetection;
    const verticalDistance = Math.abs(mouseY - (rect.top + rect.height/2));
    
    if (verticalDistance < verticalThreshold) {
      closestField.classList.add('bg-gray-100', 'dark:bg-neutral-700');
      
      const dropZone = document.createElement('div');
      dropZone.className = 'drop-indicator absolute inset-y-0 bg-gray-500 dark:bg-gray-400 transition-all duration-200';
      dropZone.style.width = '2px';
      
      // Determine if we're dragging left-to-right or right-to-left
      const isLeftToRight = this.originalLeft < rect.left;
      
      if (isLeftToRight) {
        // For left-to-right, always show the right indicator
        dropZone.style.right = '0';
        this.dropPosition = 'right';
      } else {
        // For right-to-left, use the standard approach
        const mousePosition = mouseX - rect.left;
        const isRight = mousePosition > rect.width / 2;
        
        if (isRight) {
          dropZone.style.right = '0';
          this.dropPosition = 'right';
        } else {
          dropZone.style.left = '0';
          this.dropPosition = 'left';
        }
      }
      
      closestField.style.position = 'relative';
      closestField.appendChild(dropZone);
      this.dropTarget = closestField;
      return true;
    }
    
    return false;
  }
  
  /**
   * Handle vertical drop indicators
   * @param {HTMLElement} closestField - The closest field
   * @param {DOMRect} rect - The bounding rectangle of the closest field
   * @param {number} mouseY - The mouse Y position
   */
  handleVerticalIndicator(closestField, rect, mouseY) {
    const dropZone = document.createElement('div');
    dropZone.className = 'drop-indicator absolute left-0 right-0 bg-gray-500 dark:bg-gray-400 transition-all duration-200';
    dropZone.style.height = '2px';
    
    const centerY = rect.top + (rect.height / 2);
    if (mouseY < centerY) {
      dropZone.style.top = '0';
      this.dropPosition = 'above';
    } else {
      dropZone.style.bottom = '0';
      this.dropPosition = 'below';
    }
    
    closestField.style.position = 'relative';
    closestField.classList.add('bg-gray-100', 'dark:bg-neutral-700');
    closestField.appendChild(dropZone);
    this.dropTarget = closestField;
  }
  
  /**
   * Handle the end of a drag operation
   * @param {MouseEvent} event - The mouseup event
   */
  handleDragEnd = (event) => {
    if (!this.draggedField || !this.dropTarget) {
      this.cleanupDrag();
      return;
    }
    
    this.clearRowGroups();
    
    if (this.isHorizontalDrop()) {
      this.handleHorizontalDrop();
    } else {
      this.handleVerticalDrop();
    }
    
    this.cleanupDrag();
    this.updateLayout();
    this.collectAndSavePositions();
  }
  
  /**
   * Clear existing row groups for the dragged field
   */
  clearRowGroups() {
    if (this.draggedField.dataset.rowGroup) {
      const oldGroup = this.draggedField.dataset.rowGroup;
      this.fieldTargets.forEach(field => {
        if (field.dataset.rowGroup === oldGroup) {
          field.dataset.rowGroup = '';
        }
      });
    }
  }
  
  /**
   * Check if the current drop is horizontal (left/right)
   * @returns {boolean} - True if horizontal, false if vertical
   */
  isHorizontalDrop() {
    return (this.dropPosition === 'left' || this.dropPosition === 'right') && 
           this.draggedField.dataset.width === 'half' && 
           this.dropTarget.dataset.width === 'half';
  }
  
  /**
   * Handle horizontal drop (side-by-side placement)
   */
  handleHorizontalDrop() {
    const newRowGroup = this.getNextRowGroup();
    this.dropTarget.dataset.rowGroup = newRowGroup;
    this.draggedField.dataset.rowGroup = newRowGroup;
    
    if (this.dropPosition === 'right') {
      this.dropTarget.parentNode.insertBefore(this.draggedField, this.dropTarget.nextSibling);
    } else {
      this.dropTarget.parentNode.insertBefore(this.draggedField, this.dropTarget);
    }
  }
  
  /**
   * Handle vertical drop (above/below placement)
   */
  handleVerticalDrop() {
    this.draggedField.dataset.rowGroup = '';
    
    // If dropping near a paired row, move both fields together
    if (this.dropTarget.dataset.width === 'half' && this.dropTarget.dataset.rowGroup) {
      const pairedField = this.fieldTargets.find(f => 
        f !== this.dropTarget && 
        f.dataset.rowGroup === this.dropTarget.dataset.rowGroup
      );
      
      if (pairedField) {
        if (this.dropPosition === 'above') {
          // Move both fields above the dragged field
          this.dropTarget.parentNode.insertBefore(this.draggedField, this.dropTarget);
        } else {
          // Move both fields below the dragged field
          if (pairedField.nextSibling) {
            this.dropTarget.parentNode.insertBefore(this.draggedField, pairedField.nextSibling);
          } else {
            this.dropTarget.parentNode.appendChild(this.draggedField);
          }
        }
      }
    } else {
      // Normal vertical stacking
      if (this.dropPosition === 'above') {
        this.dropTarget.parentNode.insertBefore(this.draggedField, this.dropTarget);
      } else {
        this.dropTarget.parentNode.insertBefore(this.draggedField, this.dropTarget.nextSibling);
      }
    }
  }

  /**
   * Clean up after drag operation
   */
  cleanupDrag() {
    // Restore dragged field
    if (this.draggedField) {
      this.draggedField.style.opacity = '1';
      this.draggedField.style.transform = '';
    }
    
    // Remove ghost element
    if (this.ghostElement) {
      this.ghostElement.remove();
    }
    
    // Remove drop zone
    if (this.dropZone) {
      this.dropZone.remove();
    }
    
    // Remove all indicators and highlights but keep the base styles
    this.fieldTargets.forEach(field => {
      field.classList.remove(
        'border-t-2', 'border-b-2', 'border-r-2', 'border-l-2',
        'border-t-4', 'border-b-4',
        'border-gray-500', 'border-dashed', 'bg-gray-100', 
        'dark:bg-neutral-700'
      );
      
      // Add back the base background if it was removed
      field.classList.add('bg-gray-50', 'dark:bg-neutral-950');
      
      // Remove any leftover drop zones
      const dropZones = field.querySelectorAll('.absolute');
      dropZones.forEach(zone => zone.remove());
    });
    
    // Reset drag state
    this.resetDragState();
    
    // Remove event listeners
    document.removeEventListener('mousemove', this.handleDragMove);
    document.removeEventListener('mouseup', this.handleDragEnd);
  }

  /**
   * Get the next available row group number
   * @returns {string} - The next row group number as a string
   */
  getNextRowGroup() {
    let maxGroup = 0;
    this.fieldTargets.forEach(field => {
      const group = parseInt(field.dataset.rowGroup);
      if (!isNaN(group) && group > maxGroup) {
        maxGroup = group;
      }
    });
    return (maxGroup + 1).toString();
  }

  /**
   * Update the layout of fields based on their width and row group
   */
  updateLayout() {
    let currentRowGroup = null;
    const { padding } = this.constructor.config.styling;
    
    this.fieldTargets.forEach(field => {
      // Reset field styles
      field.style.gridColumn = "1 / -1";
      field.style.position = "relative";
      field.classList.remove("border-l-2", "border-dashed", "border-gray-300", "dark:border-neutral-700");
      
      // Set consistent padding for all fields
      field.style.padding = padding;
      field.style.margin = "0";
      field.style.marginTop = padding;
      
      const width = field.dataset.width;
      const rowGroup = field.dataset.rowGroup;
      
      // Handle half-width fields
      if (width === "half") {
        if (rowGroup) {
          if (currentRowGroup !== rowGroup) {
            // First field in the row group
            currentRowGroup = rowGroup;
            field.style.gridColumn = "1 / 2";
          } else if (currentRowGroup === rowGroup) {
            // Second field in the row group
            field.style.gridColumn = "2 / 3";
            field.classList.add("border-l-2", "border-dashed", "border-gray-300", "dark:border-neutral-700");
            currentRowGroup = null;
          }
        } else {
          // Half-width field without a row group
          field.style.gridColumn = "1 / 2";
        }
      }
    });
  }

  /**
   * Toggle the width of a field between full and half
   * @param {Event} event - The click event
   */
  toggleWidth(event) {
    event.preventDefault();
    
    // Find the button and then the field
    const button = event.currentTarget;
    const field = button.closest("[data-field-layout-target='field']");
    
    if (!field) return;
    
    const fieldId = field.dataset.fieldId;
    const currentWidth = field.dataset.width;
    const newWidth = currentWidth === "full" ? "half" : "full";
    
    // Update the field's width in the database
    this.updateFieldWidth(fieldId, newWidth)
      .catch(error => {
        console.error("Error toggling width:", error);
      });
  }

  /**
   * Update a field's width in the database
   * @param {string} fieldId - The ID of the field to update
   * @param {string} width - The new width ('full' or 'half')
   * @returns {Promise} - A promise that resolves when the update is complete
   */
  async updateFieldWidth(fieldId, width) {
    const field = this.fieldTargets.find(f => f.dataset.fieldId === fieldId);
    if (!field) return;

    const updatePath = field.dataset.updateWidthPath;

    try {
      const response = await fetch(updatePath, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ width })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      // Update the field's data attribute
      field.dataset.width = width;
      
      // Update the button's icon
      const button = field.querySelector('.toggle-width-button');
      if (button) {
        const icon = button.querySelector('svg');
        if (icon) {
          if (width === 'full') {
            // Show 'shrink' icon when field is full (click to go half)
            icon.innerHTML = '<path d="m15 15 6 6m-6-6v4.8m0-4.8h4.8"/><path d="M9 19.8V15m0 0H4.2M9 15l-6 6"/><path d="M15 9l6-6m-6 6V4.2m0 4.8h4.8"/><path d="M9 4.2V9m0 0H4.2M9 9 3 3"/>';
            button.setAttribute('title', 'Shrink to half width');
          } else {
            // Show 'expand' icon when field is half (click to go full)
            icon.innerHTML = '<path d="m21 21-6-6m6 6v-4.8m0 4.8h-4.8"/><path d="M3 16.2V21m0 0h4.8M3 21l6-6"/><path d="M21 7.8V3m0 0h-4.8M21 3l-6 6"/><path d="M3 7.8V3m0 0h4.8M3 3l6 6"/>';
            button.setAttribute('title', 'Expand to full width');
          }
        }
      }
      
      // Update the layout
      this.updateLayout();
      
      // Update positions to ensure group positions are correct
      this.handleDragEnd();
      
      return data;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Collect field positions and save them to the server
   */
  collectAndSavePositions() {
    // Collect positions and additional data
    const positions = this.fieldTargets.map((field, index) => ({
      id: field.dataset.fieldId,
      position: index + 1,
      row_group: field.dataset.rowGroup || null,
      width: field.dataset.width
    }));
    
    // Send the positions to the server
    fetch(this.element.dataset.updatePositionsPath, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ positions })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return response.headers.get("content-type")?.includes("application/json") 
        ? response.json() 
        : { success: true };
    })
    .catch((error) => {
      console.error('Error updating positions:', error);
    });
  }
}