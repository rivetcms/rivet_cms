import { useEffect, useMemo, useState } from "react"
import { router } from "@inertiajs/react"
import FieldCard from "./FieldCard"

function groupRows(fields) {
  const byRow = new Map()
  for (const field of fields) {
    if (!byRow.has(field.row)) byRow.set(field.row, [])
    byRow.get(field.row).push(field)
  }
  return [...byRow.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([, rowFields]) => rowFields.sort((a, b) => a.position - b.position))
}

// Layout rules, mirrored from the server: max 2 per row, full-width alone,
// only two half-width fields can share a row.
function canDropInRow(rowFields, dragged) {
  const others = rowFields.filter((f) => f.id !== dragged.id)
  if (others.length >= 2) return false
  if (others.some((f) => f.width === "full")) return false
  if (dragged.width === "full" && others.length > 0) return false
  return true
}

function DropZone({ onDrop }) {
  const [over, setOver] = useState(false)

  return (
    <div
      className={`flex min-h-[3rem] items-stretch rounded-lg border-2 border-dashed transition-colors ${over ? "border-primary bg-primary/5" : "border-base-300 bg-base-200/30"}`}
      onDragOver={(e) => {
        e.preventDefault()
        setOver(true)
      }}
      onDragLeave={() => setOver(false)}
      onDrop={(e) => {
        e.preventDefault()
        setOver(false)
        onDrop()
      }}
    />
  )
}

export default function FieldsBuilder({ contentType, fields, onEdit }) {
  const propRows = useMemo(() => groupRows(fields), [fields])
  const [optimisticRows, setOptimisticRows] = useState(null)
  const [dragging, setDragging] = useState(null)
  const [overRow, setOverRow] = useState(null)

  useEffect(() => setOptimisticRows(null), [fields])

  const rows = optimisticRows ?? propRows

  const saveLayout = (nextRows) => {
    setOptimisticRows(nextRows)
    router.post(
      contentType.paths.update_layout,
      { rows: nextRows.map((row) => row.map((f) => f.id)) },
      { preserveScroll: true }
    )
  }

  // A successful drop can remount the dragged card before its dragend event
  // fires, so drop handlers must clear the drag state themselves.
  const endDrag = () => {
    const dragged = dragging
    setDragging(null)
    setOverRow(null)
    return dragged
  }

  // Drop into the gap before rows[zoneIndex] → the field becomes its own new row
  const dropInZone = (zoneIndex) => {
    const dragged = endDrag()
    if (!dragged) return

    let insertAt = zoneIndex
    rows.forEach((row, i) => {
      if (i < zoneIndex && row.length === 1 && row[0].id === dragged.id) insertAt -= 1
    })

    const next = rows
      .map((row) => row.filter((f) => f.id !== dragged.id))
      .filter((row) => row.length > 0)
    next.splice(insertAt, 0, [dragged])
    saveLayout(next)
  }

  // Drop onto an existing row → pair with it (or swap order within its own row)
  const dropInRow = (rowIndex) => {
    const dragged = endDrag()
    if (!dragged) return

    const targetRow = rows[rowIndex]
    if (!canDropInRow(targetRow, dragged)) return

    if (targetRow.some((f) => f.id === dragged.id)) {
      if (targetRow.length === 2) {
        const next = rows.map((row, i) => (i === rowIndex ? [...row].reverse() : row))
        saveLayout(next)
      }
      return
    }

    const targetIds = new Set(targetRow.map((f) => f.id))
    const next = rows
      .map((row) => row.filter((f) => f.id !== dragged.id))
      .map((row) => (row.length > 0 && targetIds.has(row[0].id) ? [...row, dragged] : row))
      .filter((row) => row.length > 0)
    saveLayout(next)
  }

  return (
    <div className="space-y-2">
      {dragging && <DropZone onDrop={() => dropInZone(0)} />}
      {rows.map((rowFields, rowIndex) => (
        <div key={rowFields.map((f) => f.id).join("-")}>
          <div
            className={`flex gap-2 items-stretch rounded-lg ${dragging && overRow === rowIndex && canDropInRow(rowFields, dragging) ? "ring-2 ring-primary/50" : ""}`}
            onDragOver={(e) => {
              if (dragging && canDropInRow(rowFields, dragging)) {
                e.preventDefault()
                setOverRow(rowIndex)
              }
            }}
            onDragLeave={() => setOverRow(null)}
            onDrop={(e) => {
              e.preventDefault()
              setOverRow(null)
              dropInRow(rowIndex)
            }}
          >
            {rowFields.map((field) => (
              <FieldCard
                key={field.id}
                field={field}
                onEdit={onEdit}
                dragging={dragging?.id === field.id}
                onDragStart={(e, f) => {
                  e.dataTransfer.effectAllowed = "move"
                  setDragging(f)
                }}
                onDragEnd={() => {
                  setDragging(null)
                  setOverRow(null)
                }}
              />
            ))}
          </div>
          {dragging && <div className="mt-2"><DropZone onDrop={() => dropInZone(rowIndex + 1)} /></div>}
        </div>
      ))}
    </div>
  )
}
