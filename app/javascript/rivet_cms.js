import "@hotwired/turbo-rails";
import { Application } from "@hotwired/stimulus";
import FieldLayoutController from "./controllers/field_layout_controller";
import ContentTypeFormController from "./controllers/content_type_form_controller";
import NotificationController from "./controllers/notification_controller";
import { initPrelineComponents } from "./lib/preline";

const application = Application.start();
application.debug = false;
window.Stimulus = application;

application.register("field-layout", FieldLayoutController);
application.register("content-type-form", ContentTypeFormController);
application.register("notification", NotificationController);

// Apply dark mode based on theme or system preference
function applyDarkMode(htmlElement) {
  const theme = localStorage.getItem('theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

  if (theme === 'dark' || (!theme && prefersDark) || (theme === 'auto' && prefersDark)) {
    htmlElement.classList.add('dark');
  } else {
    htmlElement.classList.remove('dark');
  }
}

// Initialize on page load
document.addEventListener("turbo:load", () => {
  applyDarkMode(document.documentElement);
  initPrelineComponents();
});

// Preserve dark mode during Turbo navigation
document.addEventListener("turbo:before-render", (event) => {
  applyDarkMode(event.detail.newBody);
});

// Re-initialize components after content updates
document.addEventListener("turbo:render", () => {
  initPrelineComponents();
});

document.addEventListener("turbo:frame-render", () => {
  initPrelineComponents();
});

// Listen for system color scheme changes
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
  const theme = localStorage.getItem('theme');
  if (theme === 'auto' || !theme) {
    applyDarkMode(document.documentElement);
  }
});

export { application };