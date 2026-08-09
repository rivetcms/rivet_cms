import * as React from "react"
import * as Inertia from "@inertiajs/react"
import { createInertiaApp } from "@inertiajs/react"
import { createRoot } from "react-dom/client"
import axios from "axios"

import Layout from "./components/Layout"
import { registerSlot } from "./lib/slots"
import { useConfirm } from "./lib/confirm"
import DashboardShow from "./pages/Dashboard/Show"
import ContentTypesIndex from "./pages/ContentTypes/Index"
import ContentTypesNew from "./pages/ContentTypes/New"
import ContentTypesShow from "./pages/ContentTypes/Show"
import ContentTypesTrash from "./pages/ContentTypes/Trash"
import ComponentsIndex from "./pages/Components/Index"
import ComponentsNew from "./pages/Components/New"
import ComponentsShow from "./pages/Components/Show"
import ContentManagerIndex from "./pages/ContentManager/Index"
import DocumentsIndex from "./pages/Documents/Index"
import DocumentsEdit from "./pages/Documents/Edit"
import DocumentsTrash from "./pages/Documents/Trash"
import MediaIndex from "./pages/Media/Index"
import TrashShow from "./pages/Trash/Show"
import AuthLogin from "./pages/Auth/Login"
import AuthSetup from "./pages/Auth/Setup"
import AuthSetPassword from "./pages/Auth/SetPassword"
import UsersIndex from "./pages/Users/Index"
import ApiTokensIndex from "./pages/ApiTokens/Index"
import ApiIndex from "./pages/Api/Index"

const pages = {
  "Dashboard/Show": DashboardShow,
  "ContentTypes/Index": ContentTypesIndex,
  "ContentTypes/New": ContentTypesNew,
  "ContentTypes/Show": ContentTypesShow,
  "ContentTypes/Trash": ContentTypesTrash,
  "Components/Index": ComponentsIndex,
  "Components/New": ComponentsNew,
  "Components/Show": ComponentsShow,
  "ContentManager/Index": ContentManagerIndex,
  "Documents/Index": DocumentsIndex,
  "Documents/Edit": DocumentsEdit,
  "Documents/Trash": DocumentsTrash,
  "Media/Index": MediaIndex,
  "Trash/Show": TrashShow,
  "Auth/Login": AuthLogin,
  "Auth/Setup": AuthSetup,
  "Auth/SetPassword": AuthSetPassword,
  "Users/Index": UsersIndex,
  "ApiTokens/Index": ApiTokensIndex,
  "Api/Index": ApiIndex,
}

// Rails verifies the token from the XSRF-TOKEN cookie via this header
axios.defaults.xsrfHeaderName = "X-CSRF-Token"

// When the host session expires mid-SPA, send the browser to the host login
// page instead of leaving a dead UI.
axios.interceptors.response.use(
  (response) => response,
  (error) => {
    const login = window?.__rivetLoginPath
    if (error.response?.status === 401 && login) {
      window.location = login
      return new Promise(() => {})
    }
    return Promise.reject(error)
  }
)

// Extension seam: a bundle loaded after this one (RivetCms.register_admin_script)
// runs before DOMContentLoaded and can register its pages here. React and
// Inertia are exposed so extensions mark them external and share this app's
// single React instance instead of bundling their own.
window.RivetCMS = {
  registerPages(map) {
    Object.assign(pages, map)
  },
  registerSlot,
  useConfirm,
  React,
  Inertia,
}

function boot() {
  createInertiaApp({
    resolve: (name) => {
      const page = pages[name]
      if (!page) throw new Error(`Unknown Inertia page: ${name}`)
      page.layout ??= (children) => <Layout>{children}</Layout>
      return page
    },
    setup({ el, App, props }) {
      createRoot(el).render(<App {...props} />)
    },
  })
}

// Module scripts run while readyState is "interactive", before
// DOMContentLoaded fires, and they run in document order. Waiting for
// DOMContentLoaded therefore guarantees every extension bundle has
// registered its pages before the first page resolves. Only a dynamically
// injected script sees "complete", where the event will never fire again.
if (document.readyState === "complete") {
  boot()
} else {
  document.addEventListener("DOMContentLoaded", boot)
}
