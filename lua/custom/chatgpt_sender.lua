local M = {}

local script_path = vim.fn.expand '~' .. '/script/send_to_chatgpt.scpt'
local lru_file = vim.fn.stdpath 'data' .. '/chatgpt_prompt_lru.json'
local max_lru = 4

-- 中英 Prompt
local prompts = {
  ['Polish'] = '请将下面的文本润色成自然、清晰、专业的日语：',
  ['To Japanese'] = '请将下面的文本翻译成自然、准确的日语：',
  ['To Chinese'] = '请将下面的文本翻译成清晰的中文：',
  ['Refactor'] = '请对下面的代码进行专业重构，提高清晰度、可维护性，并给出最终版本（不要解释过程）：',
  ['Bugs'] = '请分析下面的代码并指出可能的 bug 以及修复方案：',
  ['Performance'] = '请分析下面的代码并提出性能优化方案：',
  ['Comments'] = '请为下面的代码生成完整、专业的文档注释（例如 JSDoc 等风格）：',
  ['Test'] = '请根据下面的代码生成高质量的单元测试：',
  ['Analyze'] = '请分析下面的文本或代码逻辑，指出问题并给出建议：',
  ['Explain'] = '请解释下面的代码：',
}

--------------------------------------------------------
-- 📌 LRU（最近使用的 Prompt）功能
--------------------------------------------------------
local function read_lru()
  local f = io.open(lru_file, 'r')
  if not f then
    return {}
  end
  local content = f:read '*a'
  f:close()
  local ok, json = pcall(vim.json.decode, content)
  if ok and type(json) == 'table' then
    return json
  end
  return {}
end

local function write_lru(list)
  local f = io.open(lru_file, 'w')
  if not f then
    return
  end
  f:write(vim.json.encode(list))
  f:close()
end

local function update_lru(key)
  local lru = read_lru()

  -- 从已有列表移除旧位置
  for i, item in ipairs(lru) do
    if item == key then
      table.remove(lru, i)
      break
    end
  end

  -- 插入到最前
  table.insert(lru, 1, key)

  -- 限制最多 max_lru 个
  if #lru > max_lru then
    for i = max_lru + 1, #lru do
      lru[i] = nil
    end
  end

  write_lru(lru)
end

local function sorted_prompt_keys()
  local keys = vim.tbl_keys(prompts)
  local lru = read_lru()

  -- 创建一个映射方便排序
  local score = {}
  for i, key in ipairs(lru) do
    score[key] = 10000 - i -- 最近越大
  end

  table.sort(keys, function(a, b)
    return (score[a] or 0) > (score[b] or 0)
  end)

  return keys
end

--------------------------------------------------------
-- 📌 Telescope 功能保持不变
--------------------------------------------------------

local function get_visual(opts)
  local lines = vim.fn.getline(opts.line1, opts.line2)
  return table.concat(lines, '\n')
end

local function send_to_chatgpt(text)
  text = text:gsub('"', '\\"')
  vim.fn.jobstart({ 'osascript', script_path, text }, { detach = true })
end

-- Telescope 选择器
local function telescope_prompt_picker(opts)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local previewers = require 'telescope.previewers'

  local previewer = previewers.new_buffer_previewer {
    define_preview = function(self, entry)
      local content = prompts[entry.value]
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(content, '\n'))
    end,
  }

  pickers
    .new({}, {
      prompt_title = 'ChatGPT Prompt（支持中文 / English 搜索）',
      finder = finders.new_table {
        results = sorted_prompt_keys(), -- 🚀 包含 LRU 排序！
      },
      sorter = conf.generic_sorter {},
      previewer = previewer,
      attach_mappings = function(_, map)
        map('i', '<CR>', function(bufnr)
          local selection = require('telescope.actions.state').get_selected_entry()
          require('telescope.actions').close(bufnr)

          -- 更新 LRU
          update_lru(selection.value)

          local selected_text = get_visual(opts)
          local final_text = prompts[selection.value] .. '\n\n' .. selected_text

          send_to_chatgpt(final_text)
        end)
        return true
      end,
    })
    :find()
end

function M.setup()
  -- 命令：对选中范围调用 选择Prompt的菜单
  vim.api.nvim_create_user_command('CGPrompt', telescope_prompt_picker, { range = true })

  vim.keymap.set('v', '<leader>am', ":'<,'>CGPrompt<CR>", {
    silent = true,
    desc = 'Fancy Telescope ChatGPT prompt menu (with LRU)',
  })

  -- 命令：对选中范围调用 AppleScript
  vim.api.nvim_create_user_command('SendToChatGPT', function(opts)
    -- 取选中行
    local selected_text = get_visual(opts) .. '\n\n\n\n'

    local script = vim.fn.expand '~' .. '/script/send_to_chatgpt.scpt'

    vim.fn.jobstart({ 'osascript', script, selected_text }, { detach = true })
  end, { range = true })

  -- Visual 模式下的快捷键，比如 <leader>cg
  vim.keymap.set('v', '<leader>ao', ":'<,'>SendToChatGPT<CR>", {
    silent = true,
    desc = 'Send selection to ChatGPT',
  })
end

return M
