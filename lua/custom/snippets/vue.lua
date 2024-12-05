require('luasnip.session.snippet_collection').clear_snippets 'elixir'

local ls = require 'luasnip'

local s = ls.snippet
-- local sn = ls.snippet_node
-- local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
-- local f = ls.function_node
-- local c = ls.choice_node
-- local d = ls.dynamic_node
-- local r = ls.restore_node
ls.add_snippets('all', {
  s('clg', {
    t 'console.log(',
    i(1),
    t ')',
  }),

  s('wat', {
    t 'watch(',
    i(1),
    t ',()=>{',
    i(2),
    t '})',
  }),

  s('effct', {
    t 'watchEffect(()=>{',
    i(1),
    t '})',
  }),

  s('compu', {
    t 'computed(()=>',
    i(1),
    t ')',
  }),

  s('cmodel', {
    t 'const { modelValue } = defineModels<{',
    i(1),
    t '}>()',
  }),
  s('cemits', {
    t 'const emits = defineEmits<{',
    i(1),
    t '}>()',
  }),
  s('cprops', {
    t 'defineProps<{',
    i(1),
    t '}>()',
  }),
  s('copt', {
    t 'defineOptions<{',
    i(1),
    t 'inheritAttrs: false',
    i(2),
    t '}>()',
  }),
  s('cdefault', {
    t 'const props = withDefaults(defineProps<{',
    i(1),
    t '}>(),{',
    t '})',
  }),

  s('mdia', {
    t 'const dialogModule = useDialogModule()',
  }),
  s('msna', {
    t 'const snackbarModule = useSnackbarModule()',
  }),
  s('male', {
    t 'const alertModule = useAlertModule()',
  }),
  s('mme', {
    t 'const meModule = useUserMeModule()',
  }),
  s('mmes', {
    t 'const meStore = UserMeStore.inject()',
  }),
  s('muser', {
    t 'const userModule = useUserModule()',
  }),
  s('mmbox', {
    t 'const mboxModule = useMessageBoxModule()',
  }),
  s('mmboxs', {
    t 'const mboxStore = MessageBoxStore.inject()',
  }),

  s('ass', {
    t "@use '@assets/stylesheets/settings' as *;",
  }),
})
