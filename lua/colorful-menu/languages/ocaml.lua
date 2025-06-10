local M = {}
local utils = require("colorful-menu.utils")
local Kind = require("colorful-menu").Kind

---@param completion_item lsp.CompletionItem
---@return string
local function hl_by_kind(completion_item)
    local kind = completion_item.kind
    local detail = completion_item.detail
    local highlight_name
    if kind == Kind.TypeParameter then
        highlight_name = utils.hl_exist_or("@lsp.type.TypeParameter", "@type", "ocaml")
    elseif kind == Kind.Value and detail and detail:find("->") then
        highlight_name = utils.hl_exist_or("@lsp.type.function.ocaml", "@function", "ocaml")
    elseif kind == Kind.Value then
        highlight_name = utils.hl_exist_or("@lsp.type.variable", "@variable", "ocaml")
    elseif kind == Kind.Constructor then
        highlight_name = utils.hl_exist_or("@lsp.type.enumMember.ocaml", "@constructor", "ocaml")
    elseif kind == Kind.Module then
        highlight_name = utils.hl_exist_or("@module.ocaml", "@module", "ocaml")
    else
        utils.hl_by_kind(kind, "ocaml")
    end
    return highlight_name
end

-- TODO: max sure the full "->" is highlighted, as well as "'a" not just the "-" and "'" respectively
-- Look for the following:
-- { "@operator.ocaml",
--       range = { 49, 50 },
--       text = "-"
--     }, { "@punctuation.delimiter.ocaml",
--       range = { 50, 51 },
--       text = ">"
--     }, { "@punctuation.delimiter.ocaml",
--       range = { 56, 57 },
--       text = ">"
--     },

---@param hl CMHighlights
---@return CMHighlights
local function cleanup_hl(hl)
    for i, h in ipairs(hl.highlights) do
        -- Check for ->
        if h.text == "-" and hl.highlights[i + 1] and hl.highlights[i + 1].text == ">" then
            h.text = "->"
            h.range[2] = hl.highlights[i + 1].range[2]
            table.remove(hl.highlights, i + 1)
        end
        -- check for 'a
        if h.range[1] > 0 and hl.text:sub(h.range[1], h.range[1]) == "'" then
            h.range[1] = h.range[1] - 1
            h.text = "'" .. h.text
        end
    end
    return hl
end

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
function M.ocamllsp(completion_item, ls)
    if completion_item.detail then
        local detail = completion_item.detail or ""
        local highlights = utils.highlight_range(detail, ls, 0, #detail)
        local text = completion_item.label
        local detail_start = #completion_item.label
        if detail and string.find(detail, "\n") == nil and string.find(detail, "\r") == nil then
            local spaces = utils.align_spaces(completion_item.label, detail)
            -- If there are any information, append it
            text = completion_item.label .. spaces .. detail
            if #text > 60 then
                text = string.sub(text, 1, 57) .. "..."
            end
            detail_start = #completion_item.label + #spaces
            table.insert(highlights.highlights, 1, {
                hl_by_kind(completion_item),
                range = { 0, #completion_item.label },
                text = completion_item.label,
            })
        end

        -- offset highlights by detail_start except for the first highlight
        for i, hl in ipairs(highlights.highlights) do
            if i > 1 then
                hl.range[1] = hl.range[1] + detail_start
                hl.range[2] = hl.range[2] + detail_start
            end
        end

        highlights.text = text
        highlights = cleanup_hl(highlights)
        return highlights
    end

    return require("colorful-menu.languages.default").default_highlight(
        completion_item,
        completion_item.detail,
        "ocaml"
    )
end

return M

-- highlights = { { "@comment",
--       range = { 0, 15 },
--       text = "generate_events"
--     }, { "@module.ocaml",
--       range = { 26, 32 },
--       text = "Stream"
--     }, { "@module.ocaml",
--       range = { 26, 32 },
--       text = "Stream"
--     }, { "@punctuation.delimiter.ocaml",
--       range = { 32, 33 },
--       text = "."
--     }, { "@variable.ocaml",
--       range = { 33, 34 },
--       text = "t"
--     }, { "@operator.ocaml",
--       range = { 35, 36 },
--       text = "-"
--     }, { "@punctuation.delimiter.ocaml",
--       range = { 36, 37 },
--       text = ">"
--     }, { "@punctuation.delimiter.ocaml",
--       range = { 42, 43 },
--       text = ">"
--     }, { "@variable.ocaml",
--       range = { 44, 48 },
--       text = "unit"
--     }, { "@operator.ocaml",
--       range = { 49, 50 },
--       text = "-"
--     }, { "@punctuation.delimiter.ocaml",
--       range = { 50, 51 },
--       text = ">"
--     }, { "@punctuation.delimiter.ocaml",
--       range = { 56, 57 },
--       text = ">"
--     }, { "@character.ocaml",
--       range = { 58, 60 },
--       text = "'d"
--     } },
--   text = "generate_events        'a Stream.t -> 'b -> unit -> 'c -> 'd"
-- }
--
