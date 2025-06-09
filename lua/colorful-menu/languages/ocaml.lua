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

---@param completion_item lsp.CompletionItem
---@param ls string
---@return CMHighlights
function M.ocamllsp(completion_item, ls)
    if completion_item.detail then
        local highlights = utils.highlight_range(completion_item.detail, ls, 0, #completion_item.detail)
        local text = completion_item.label
        local detail_start = #completion_item.label
        if
            completion_item.detail
            and string.find(completion_item.detail, "\n") == nil
            and string.find(completion_item.detail, "\r") == nil
        then
            local spaces = utils.align_spaces(completion_item.label, completion_item.detail)
            -- If there are any information, append it
            text = completion_item.label .. spaces .. completion_item.detail
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
