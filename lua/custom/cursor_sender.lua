local M = {}

local prompts = {
  ['Polish'] = '请将下面的文本润色成自然、清晰、专业的日语：',
  ['To Japanese'] = '请将下面的文本翻译成自然、准确的日语：',
  ['To Chinese'] = '请将下面的文本翻译成清晰的中文：',
  ['Refactor'] = '请对下面的代码进行专业重构，提高清晰度、可维护性，并给出最终版本（不要解释过程）：',
  ['Bugs'] = '请分析下面的代码并指出可能的 bug 以及修复方案：',
  ['Performance'] = '请分析下面的代码并提出性能优化方案：',
  ['Comments'] = '请为下面的代码生成完整、专业的文档注释（例如 JSDoc 等风格）：',
  ['Test'] = '请根据下面的代码生成高质量的单元测试：',
  ['Diff Test'] = '请根据我的修改内容生成高质量的测试案例：',
  ['Analyze'] = '请分析下面的文本或代码逻辑，指出问题并给出建议：',
  ['Explain'] = '请解释下面的代码：',
}

local SCRIPT_PATH = vim.fn.expand '~' .. '/script/cursor_chat_composed.scpt'

local function get_file_range(opts)
  local start_line = opts.line1
  local end_line = opts.line2

  -- 获取项目相对路径，而不是纯文件名
  local file = vim.fn.expand '%:.' -- %:. 表示相对路径
  -- 构建 Cursor 所需格式：@path/to/file.rb:10-20
  local range_cmd = string.format('@%s:%d-%d', file, start_line, end_line)
  return range_cmd
end

-- 发送消息到 Cursor
local function send_to_cursor(message, workspace)
  workspace = workspace or vim.fn.getcwd()
  vim.fn.jobstart({
    'osascript',
    SCRIPT_PATH,
    message,
    workspace,
  }, { detach = true })
end

-- Telescope picker
local function create_previewer()
  local previewers = require 'telescope.previewers'
  return previewers.new_buffer_previewer {
    define_preview = function(self, entry)
      local prompt_text = prompts[entry.value] or ''
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { prompt_text })
    end,
  }
end

local function create_action_handler(range_cmd, workspace)
  return function(bufnr)
    local actions = require 'telescope.actions'
    local action_state = require 'telescope.actions.state'
    local selected_entry = action_state.get_selected_entry()

    if not selected_entry or not selected_entry.value then
      return
    end

    local prompt_text = prompts[selected_entry.value]
    if not prompt_text then
      return
    end

    local message = string.format('%s\n%s', prompt_text, range_cmd)
    actions.close(bufnr)
    send_to_cursor(message, workspace)
  end
end

local function choose_cursor_command(opts)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values

  local range_cmd = get_file_range(opts)
  local workspace = vim.fn.getcwd()
  local previewer = create_previewer()
  local action_handler = create_action_handler(range_cmd, workspace)

  local picker_config = {
    prompt_title = 'Cursor @Commands',
    finder = finders.new_table {
      results = vim.tbl_keys(prompts),
    },
    sorter = conf.generic_sorter {},
    previewer = previewer,
    attach_mappings = function(_, map)
      map('i', '<CR>', action_handler)
      return true
    end,
  }

  pickers.new({}, picker_config):find()
end

function M.setup()
  -- 定义用户命令
  vim.api.nvim_create_user_command('CursorCommand', choose_cursor_command, {
    range = true,
    desc = 'Pick a Cursor command and send selected range',
  })

  vim.api.nvim_create_user_command('SendToCursor', function(opts)
    local range_cmd = get_file_range(opts)
    send_to_cursor(range_cmd .. '\n\n')
  end, {
    range = true,
    desc = 'Send selected range to Cursor',
  })

  -- 定义键位映射
  vim.keymap.set('v', '<leader>rm', ":'<,'>CursorCommand<cr>", {
    silent = true,
    desc = 'cursor: pick @command + range',
  })

  vim.keymap.set('v', '<leader>ro', ":'<,'>SendToCursor<cr>", {
    silent = true,
    desc = 'Send selection to Cursor',
  })
end

return M
