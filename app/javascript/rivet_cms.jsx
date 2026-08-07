import { createInertiaApp } from "@inertiajs/react"
import { createRoot } from "react-dom/client"
import axios from "axios"

import Layout from "./components/Layout"
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
import MediaIndex from "./pages/Media/Index"
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
  "Media/Index": MediaIndex,
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
