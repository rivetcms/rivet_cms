import "@hotwired/turbo-rails"
import "./controllers"
import 'basecoat-css/all';

// View transitions for turbo frame navigation
addEventListener("turbo:before-frame-render", (event) => {
    if (document.startViewTransition) {
        const originalRender = event.detail.render
        event.detail.render = async (currentElement, newElement) => {
            const transition = document.startViewTransition(() => originalRender(currentElement, newElement))
            await transition.finished
        }
    }
})
