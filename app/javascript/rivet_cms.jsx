import { createInertiaApp } from "@inertiajs/react"
import { createRoot } from "react-dom/client"
import axios from "axios"

import Layout from "./components/Layout"
import DashboardShow from "./pages/Dashboard/Show"
import ContentTypesIndex from "./pages/ContentTypes/Index"
import ContentTypesNew from "./pages/ContentTypes/New"
import ContentTypesEdit from "./pages/ContentTypes/Edit"
import ContentTypesShow from "./pages/ContentTypes/Show"
import ComponentsIndex from "./pages/Components/Index"
import ComponentsNew from "./pages/Components/New"
import ComponentsEdit from "./pages/Components/Edit"

const pages = {
  "Dashboard/Show": DashboardShow,
  "ContentTypes/Index": ContentTypesIndex,
  "ContentTypes/New": ContentTypesNew,
  "ContentTypes/Edit": ContentTypesEdit,
  "ContentTypes/Show": ContentTypesShow,
  "Components/Index": ComponentsIndex,
  "Components/New": ComponentsNew,
  "Components/Edit": ComponentsEdit,
}

// Rails verifies the token from the XSRF-TOKEN cookie via this header
axios.defaults.xsrfHeaderName = "X-CSRF-Token"

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
