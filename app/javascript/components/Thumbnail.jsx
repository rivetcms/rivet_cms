import { useState } from "react"

// Stays invisible (letting the container's sunken background show) until the
// image has loaded, then fades in. Prevents the alt-text flash while variants
// process. The ref check catches images already complete from cache.
export default function Thumbnail({ src, alt, className = "" }) {
  const [loaded, setLoaded] = useState(false)
  const ref = (el) => {
    if (el?.complete && el.naturalWidth > 0) setLoaded(true)
  }

  return (
    <img
      ref={ref}
      src={src}
      alt={alt}
      loading="lazy"
      onLoad={() => setLoaded(true)}
      className={`${className} transition-opacity duration-200 ${loaded ? "opacity-100" : "opacity-0"}`}
    />
  )
}
