// Styled replacement for a native <select> used as a list filter: DaisyUI
// dropdown + menu with a check on the active choice. Options are
// { value, label }; the empty value is the "all" choice.
export default function FilterSelect({ options, value, allLabel, onChange, width = "w-44" }) {
  const current = options.find((option) => option.value === value)

  const pick = (next) => {
    document.activeElement?.blur()
    onChange(next)
  }

  const Item = ({ optionValue, children }) => (
    <li>
      <button type="button" onClick={() => pick(optionValue)} className="flex items-center justify-between text-[13px]">
        {children}
        {(current?.value || "") === optionValue && (
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
        )}
      </button>
    </li>
  )

  return (
    <div className="dropdown">
      <div tabIndex={0} role="button" className={`btn btn-ghost ${width} justify-between border border-base-300 font-medium`}>
        <span className="truncate">{current ? current.label : allLabel}</span>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="shrink-0 text-base-content/50"><path d="m6 9 6 6 6-6"/></svg>
      </div>
      <ul tabIndex={0} className="dropdown-content menu z-10 mt-1 max-h-80 w-52 flex-nowrap overflow-y-auto rounded-box border border-base-300 bg-base-100 p-1.5 shadow-(--shadow-raised)">
        <Item optionValue="">{allLabel}</Item>
        {options.map((option) => (
          <Item key={option.value} optionValue={option.value}>{option.label}</Item>
        ))}
      </ul>
    </div>
  )
}
