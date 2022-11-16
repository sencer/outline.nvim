if vim.g.loaded_outline ~= nil then
	return
end
vim.g.loaded_outline = true

vim.keymap.set("n", "<F9>", require("outline").outline, { noremap = true })
