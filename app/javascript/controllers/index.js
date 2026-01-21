import { application } from "./application"

import ThemeController from "./theme_controller"
import ContentTypeFormController from "./content_type_form_controller"
import CategoryComboboxController from "./category_combobox_controller"
import FieldSortableController from "./field_sortable_controller"
import FieldDrawerController from "./field_drawer_controller"

application.register("theme", ThemeController)
application.register("content-type-form", ContentTypeFormController)
application.register("category-combobox", CategoryComboboxController)
application.register("field-sortable", FieldSortableController)
application.register("field-drawer", FieldDrawerController)