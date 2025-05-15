import HSAccordion from 'preline/src/plugins/accordion'
import HSOverlay from 'preline/src/plugins/overlay'
import HSDropdown from 'preline/src/plugins/dropdown'
import HSTooltip from 'preline/src/plugins/tooltip'
import HSCollapse from 'preline/src/plugins/collapse'
import HSSelect from 'preline/src/plugins/select'
import HSThemeSwitch from 'preline/src/plugins/theme-switch'
import HSTabs from 'preline/src/plugins/tabs'

export function initPrelineComponents() {
  HSAccordion.autoInit()
  HSOverlay.autoInit()
  HSDropdown.autoInit()
  HSTooltip.autoInit()
  HSCollapse.autoInit()
  HSSelect.autoInit()
  HSThemeSwitch.autoInit()
  HSTabs.autoInit()
}
