import { Controller } from "@hotwired/stimulus"
import Notification from "@stimulus-components/notification"

// Connects to data-controller="notification"
export default class extends Notification {
  connect() {
    super.connect()
    console.log("Connected to notification controller")
    
    // Add subtle pulse animation after appearing
    setTimeout(() => {
      if (this.element) {
        this.element.classList.add('animate-pulse')
        
        // Remove pulse after 1 second
        setTimeout(() => {
          if (this.element) {
            this.element.classList.remove('animate-pulse')
          }
        }, 1000)
      }
    }, 300)
  }
} 