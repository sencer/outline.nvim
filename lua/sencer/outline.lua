local M = {}

local ui_symbol_map = {
	assignment = "⇔",
	class_definition = "ℂ",
	class_specifier = "ℂ",
	enum_specifier = "ε",
	function_declaration = "ƒ",
	function_declarator = "ƒ",
	function_definition = "ƒ",
	method_definition = "ƒ",
	namespace_definition = "ℕ",
}

-- Iterate matches (from {lang}/outline.scm) and insert them into a tree structure that reflects the nesting structure
-- of the code itself.
local function get_outline_tree(bufnr)
	local function recursively_insert_sorted(tree, item)
		for _, node in pairs(tree) do
			-- Avoid duplicates.
			if node.node.start == item.start and node.node.end_ == item.end_ then
				return
			end

			if node.node.end_ >= item.end_ then
				recursively_insert_sorted(node.children, item)
				return
			end
		end

		table.insert(tree, { node = item, children = {} })
	end

	local items = {}
	for _, match in pairs(require("nvim-treesitter.query").get_matches(bufnr, "outline")) do
		local startl, _ = match.type.node:start()
		local endl, _ = match.type.node:end_()

		local name = match.name and vim.treesitter.get_node_text(match.name.node, bufnr) or "Anonymous"
		local typ = ui_symbol_map[match.type and match.type.node:type()] or match.type.node:type()

		local item = {
			start = startl + 1,
			end_ = endl + 1,
			text = name .. " " .. typ,
		}

		recursively_insert_sorted(items, item)
	end

	return items
end

-- Creates text representation of the trees.
local function build_strings(tree, last_child_tree)
	for i, node in ipairs(tree) do
		local text = node.node.text

		local last_child = i == #tree
		if #last_child_tree > 0 then
			text = (last_child and "└─ " or "├─ ") .. text
			for j, p_last_child in pairs(last_child_tree) do
				if j == #last_child_tree then
					break
				end
				text = (p_last_child and "   " or "│  ") .. text
			end
		end

		node.node.text = text
		build_strings(node.children, vim.list_extend({ last_child }, last_child_tree))
	end
end

local function flatten_and_build_qf_format(tree, bufnr)
	local list = {}

	for _, node in pairs(tree) do
		local n = node.node
		table.insert(list, { bufnr = bufnr, text = n.text, lnum = n.start })

		vim.list_extend(list, flatten_and_build_qf_format(node.children, bufnr))
	end

	return list
end

local function get_qf_items(bufnr)
	local items = get_outline_tree(bufnr)
	build_strings(items, {})
	return flatten_and_build_qf_format(items, bufnr)
end

M.toggle = function(bufnr)
	if vim.t.outline_window then
		vim.api.nvim_win_close(vim.t.outline_window, true)
		return
	end

	bufnr = bufnr or vim.fn.bufnr()

	local items = get_qf_items(bufnr)

	if not next(items) then
		print("Nothing the show. Perhaps we don't know that language.")
		return
	end

	vim.fn.setloclist(vim.fn.bufwinnr(bufnr), {}, " ", {
		nr = "$",
		title = "Outline",
		quickfixtextfunc = require("sencer.format").text,
		items = items,
	})

	vim.cmd.lopen()
	local winid = vim.fn.bufwinid(vim.fn.bufnr())
	vim.t.outline_window = winid

	vim.wo.foldexpr = '{l -> count(l, "├") + count(l, "│") + count(l, "└")}(getline(v:lnum))'
	vim.wo.foldmethod = "expr"
	vim.wo.foldtext = [[repeat(" ", 3*(v:foldlevel-1))."└ ".(v:foldend-v:foldstart)." lines"]]
	vim.wo.list = false
	vim.wo.wrap = false
	vim.wo.spell = false
	vim.api.nvim_create_augroup("Outline", { clear = true })
	vim.api.nvim_create_autocmd("WinClosed", {
		group = "Outline",
		pattern = tostring(winid),
		callback = function()
			vim.t.outline_window = nil
		end,
	})
end

return M
