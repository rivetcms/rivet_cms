import pluralize from "pluralize"

export function generateSlug(text) {
  return text
    .toLowerCase()
    .replace(/\s+/g, "-")        // spaces → hyphens
    .replace(/_+/g, "-")         // underscores → hyphens
    .replace(/[^\w\-]+/g, "")    // remove non-word chars
    .replace(/\d+/g, "")         // remove numbers
    .replace(/\-\-+/g, "-")      // collapse "--" to "-"
    .replace(/^-+/, "")          // trim start hyphens
    .replace(/-+$/, "")          // trim end hyphens
}

// Slug derived from a name, singularized or pluralized to match the type
export function slugFromName(name, { singular = false } = {}) {
  const trimmed = name.trim()
  if (!trimmed || trimmed.length < 3) return ""

  let slug = generateSlug(trimmed)
  if (!slug) return ""

  slug = singular ? pluralize.singular(slug) : pluralize(slug)
  return slug.replace(/[^a-z\-]/g, "")
}

// Clean a slug as the user types (spaces/underscores → hyphens, strip invalid
// chars). Digits stay: the server allows them for both types and entries.
export function cleanSlug(value) {
  return value
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/_+/g, "-")
    .replace(/[^a-z0-9\-]/g, "")
    .replace(/\-\-+/g, "-")
}
