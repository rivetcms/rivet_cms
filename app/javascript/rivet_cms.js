import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import FieldLayoutController from "./controllers/field_layout_controller"
import ContentTypeFormController from "./controllers/content_type_form_controller"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Register controllers
application.register("field-layout", FieldLayoutController)
application.register("content-type-form", ContentTypeFormController)
document.addEventListener("turbo:load", function(event) {  
  // Mobile menu toggle
  const mobileMenuButton = document.querySelector('[aria-controls="mobile-menu"]')
  const mobileMenu = document.getElementById('mobile-menu')
  
  if (mobileMenuButton && mobileMenu) {
    mobileMenuButton.addEventListener('click', () => {
      const expanded = mobileMenuButton.getAttribute('aria-expanded') === 'true'
      mobileMenuButton.setAttribute('aria-expanded', !expanded)
      mobileMenu.classList.toggle('hidden')
    })
  }
});

export { application }