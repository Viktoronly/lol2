script_name('CorrectionWords')
script_authors('Royan Millans')
local dlstatus = require('moonloader').download_status
local res = pcall(require, "lib.moonloader")
local res, sampev = pcall(require, 'lib.samp.events')
local lanes = require('lanes').configure()
local res, inicfg = pcall(require, "inicfg")
local res, encoding = pcall(require, "encoding")
local res = pcall(require, "requests")
--downloadUrlToFile("http://drp-scripts.ru/requests.lua", getWorkingDirectory() .. '/lib/requests.lua', checkdownload)


encoding.default = 'CP1251'
u8 = encoding.UTF8
old_message = nil
currect_message = nil
message_on_chat_status = 0
settings = inicfg.load({
  main = {
  mode = 2,
  hint = 1,
  auto_upper_and_point = true
}
  }, 'CorrectionWords')

--no_symbol = {':', '.', '/', "\\", '!', '?', ',', '"', "'", '@', '#', '�', '$', ';', '%', '^', '*', '(', ')', '[', ']', '{', '}', '~', '`', '-', '_'}

local russian_characters = {
    [168] = '�', [184] = '�', [192] = '�', [193] = '�', [194] = '�', [195] = '�', [196] = '�', [197] = '�', [198] = '�', [199] = '�', [200] = '�', [201] = '�', [202] = '�', [203] = '�', [204] = '�', [205] = '�', [206] = '�', [207] = '�', [208] = '�', [209] = '�', [210] = '�', [211] = '�', [212] = '�', [213] = '�', [214] = '�', [215] = '�', [216] = '�', [217] = '�', [218] = '�', [219] = '�', [220] = '�', [221] = '�', [222] = '�', [223] = '�', [224] = '�', [225] = '�', [226] = '�', [227] = '�', [228] = '�', [229] = '�', [230] = '�', [231] = '�', [232] = '�', [233] = '�', [234] = '�', [235] = '�', [236] = '�', [237] = '�', [238] = '�', [239] = '�', [240] = '�', [241] = '�', [242] = '�', [243] = '�', [244] = '�', [245] = '�', [246] = '�', [247] = '�', [248] = '�', [249] = '�', [250] = '�', [251] = '�', [252] = '�', [253] = '�', [254] = '�', [255] = '�',
}
function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function string.rlower(s)
    s = s:lower()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:lower()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then -- upper russian characters
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then -- �
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end
function string.rupper(s)
    s = s:upper()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:upper()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 224 and ch <= 255 then -- lower russian characters
            output = output .. russian_characters[ch - 32]
        elseif ch == 184 then -- �
            output = output .. russian_characters[168]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end

local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub(" ", "+")
  return url
end

local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

local urldecode = function(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end

function async_http_request(method, url, args, resolve, reject)
	local request_lane = lanes.gen('*', {package = {path = package.path, cpath = package.cpath}}, function()
		local requests = require 'requests'
        local ok, result = pcall(requests.request, method, url, args)
        if ok then
            result.json, result.xml = nil, nil -- cannot be passed through a lane
            return true, result
        else
            return false, result -- return error
        end
    end)
    if not reject then reject = function() end end
    lua_thread.create(function()
        local lh = request_lane()
        while true do
            local status = lh.status
            if status == 'done' then
                local ok, result = lh[1], lh[2]
                if ok then resolve(result) else reject(result) end
                return
            elseif status == 'error' then
                return reject(lh[1])
            elseif status == 'killed' or status == 'cancelled' then
                return reject(status)
            end
            wait(0)
        end
    end)
end

function main()
  -- �������� �� ��������� ����� --

	while not isSampAvailable() do
		wait(0)
	end

  ---------------------------------
  sampRegisterChatCommand("checkw", check_command) -- ������ ������� ��� �������� ����
  sampRegisterChatCommand("cwset", settings_command) -- ������ ������� ��� �������� ����� �������
  sampRegisterChatCommand("chint", hint_command) -- ������/�������� ��������� ��� ����� � ����
  sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} by {00AAFF}R{FFFFFF}oyan {00AAFF}M{FFFFFF}illans", -1) -- ����� ���������� ���������
  if settings.main.hint == 1 then
    sampAddChatMessage("{00AAFF}[CorrectionWords] /cwset{FFFFFF} - ��������� | {00AAFF}/checkw{FFFFFF} - ��������� �����/�����������", -1) -- ����� ���������� ���������  
    sampAddChatMessage("{00AAFF}[CorrectionWords] CTRL + X{FFFFFF} - ��������� ����� � �������� ���� | {00AAFF}/chint{FFFFFF} - ������ ��� ���������", -1) -- ����� ���������� ���������  
  end
	while true do -- ����������� ����
		wait(0)
    if isKeyDown(17) and isKeyJustPressed(88) and sampIsChatInputActive() then -- CTRL + X � ������ ���
      local message_user = sampGetChatInputText() -- ������� ����� � ����(�����)
      correctionInput(message_user) -- ���������� ��� �� ������� �����������
    end
    if isKeyDown(17) and isKeyJustPressed(90) and sampIsChatInputActive() and old_message ~= nil -- CTRL + Z, ������ ��� � ������ ��������� �� �����
    then
      sampSetChatInputText(old_message) -- ������������� ������ ���������
      old_message = nil -- �������� ����������
    end
    if isKeyJustPressed(113) and currect_message ~= nil then -- ���� ����� F2 � ��������� � ������������� �� �����
      if settings.main.mode == 2 then 
        if currect_typecommand == nil then 
         sampSendChat(string.format('���..%s.', currect_message)) 
        else
          sampSendChat(string.format('/%s ���..%s.', currect_typecommand, currect_message))  
          currect_typecommand = nil
        end
      end -- ������� ��� ��������� ��� - "���.. [������]."
      if settings.main.mode == 3 then setClipboardText(currect_message) sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������������ ����� �����������", -1) end -- ������� ��� ��������� ��� - "���.. [������]."
      currect_message = nil -- �������� ����������
    end
	end
end

function check_command(text)
  if text ~= "" then -- ��������� ��������� �� �������
    text = trim(text)
    if string.len(text) < 100 then -- ��������� �� �������� ���������
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������������ ��������..", -1)
      local url_text = urlencode(text) -- ����������� ��������� � URL ������
      local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
      async_http_request("GET", url, nil, -- GET ������
      function(response) -- ���� ����� ������
        local words = decodeJson(response.text) -- ���������� JSON ����� � table
        if words[1] ~= nil then -- ���� table �� ������
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������� ������:", -1)
          local used_words = {} -- ������� ������ ��� ��� ��������� ����
          for k, v in pairs(words) do -- ������� �������
            if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
              text = text:gsub(u8:decode(v['word']), string.format("{20B802}%s{FFFFFF}", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
              used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
            end
          end
          used_words = nil -- ������� ������ �������������� ����
          sampAddChatMessage(text, -1) -- ������� ������������ ��������� ���������
        else
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ �� �������", -1)
        end
      end,
      function(err) -- � ������ ������� ��� �������� � �������� �������
        sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
      end)
    else
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������� ������� ����������� ��� �����", -1)  
    end
  else
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} /checkw [�����/�����������]", -1)  
  end
end

function correctionInput(message)
  if message ~= "" then -- ��������� ��������� �� �������
      message = trim(message)
      if settings.main.auto_upper_and_point then
        local fist_symbol = string.sub(message, 1, 1) -- �������� ������ ������ �����
        local last_symbol = string.sub(message, string.len(message), string.len(message)) -- �������� ��������� ������ ������
        message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- ��������� ������ ������ � ������� �������
        if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- � ������ ���������� ��������� �����, ������ �����
        sampSetChatInputText(message)
      end
      local url_text = urlencode(message) -- ����������� ��������� � URL ������ 
      local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
      async_http_request("GET", url, nil, -- GET ������
      function(response) -- ���� ����� ������
        local words = decodeJson(response.text) -- ���������� JSON ����� � table
        if words[1] ~= nil then -- ���� table �� ������
          old_message = message
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ����������", -1)
          local used_words = {} -- ������� ������ ��� ��� ��������� ����
          for k, v in pairs(words) do -- ������� �������
            if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
              message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
              used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
            end
          end
          used_words = nil -- ������� ������ �������������� ����
          message = message:gsub('//', '/')
          sampSetChatInputText(message) -- ������������� ������������ ����� � input
        else
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ �� �������", -1)
        end
      end,
      function(err) -- � ������ ������� ��� �������� � �������� �������
        sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
      end)
  end
end

function sampev.onSendChat(message)
if settings.main.mode ~= 0 then
  if message ~= "" and settings.main.mode == 3 then
      message = trim(message)
      if settings.main.auto_upper_and_point then
        local fist_symbol = string.sub(message, 1, 1) -- �������� ������ ������ �����
        local last_symbol = string.sub(message, string.len(message), string.len(message)) -- �������� ��������� ������ ������
        message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- ��������� ������ ������ � ������� �������
        if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- � ������ ���������� ��������� �����, ������ �����
      end
        local url_text = urlencode(message) -- ����������� ��������� � URL ������ 
        local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
        async_http_request("GET", url, nil, -- GET ������
        function(response) -- ���� ����� ������
          local words = decodeJson(response.text) -- ���������� JSON ����� � table
          if words[1] ~= nil then -- ���� table �� ������
            local used_words = {} -- ������� ������ ��� ��� ��������� ����
            currect_message = '' -- ������� ������ ���������� ��� ���������� � ��� ����������� ����
            currect_typecommand = nil
            for k, v in pairs(words) do -- ������� �������
              if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
                --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
                if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
              end
            end
            used_words = nil -- ������� ������ �������������� ����
            sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} ������� ������:{20B802}%s{FFFFFF}. ������� - \"F2\" ��� �����������", currect_message), -1)
          end
        end,
        function(err) -- � ������ ������� ��� �������� � �������� �������
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
        end)
    end
    if message ~= "" and settings.main.mode == 2 then
      message = trim(message)
        if settings.main.auto_upper_and_point then
        local fist_symbol = string.sub(message, 1, 1) -- �������� ������ ������ �����
        local last_symbol = string.sub(message, string.len(message), string.len(message)) -- �������� ��������� ������ ������
        message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- ��������� ������ ������ � ������� �������
        if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- � ������ ���������� ��������� �����, ������ �����
      end
        local url_text = urlencode(message) -- ����������� ��������� � URL ������ 
        local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
        async_http_request("GET", url, nil, -- GET ������
        function(response) -- ���� ����� ������
          local words = decodeJson(response.text) -- ���������� JSON ����� � table
          if words[1] ~= nil then -- ���� table �� ������
            local used_words = {} -- ������� ������ ��� ��� ��������� ����
            currect_message = '' -- ������� ������ ���������� ��� ���������� � ��� ����������� ����
            currect_typecommand = nil
            for k, v in pairs(words) do -- ������� �������
              if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
                --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
                if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
              end
            end
            used_words = nil -- ������� ������ �������������� ����
            sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} ������� ������:{20B802}%s{FFFFFF}. ������� - \"F2\" ��� ������", currect_message), -1)
          end
        end,
        function(err) -- � ������ ������� ��� �������� � �������� �������
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
        end)
    end
    if message ~= "" and message_on_chat_status == 0 and settings.main.mode == 1 then -- ��������� ��������� �� �������
        message = trim(message)
        if settings.main.auto_upper_and_point then
          local fist_symbol = string.sub(message, 1, 1) -- �������� ������ ������ �����
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- �������� ��������� ������ ������
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- ��������� ������ ������ � ������� �������
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- � ������ ���������� ��������� �����, ������ �����
        end
        local url_text = urlencode(message) -- ����������� ��������� � URL ������ 
        local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
        async_http_request("GET", url, nil, -- GET ������
        function(response) -- ���� ����� ������
          local words = decodeJson(response.text) -- ���������� JSON ����� � table
          if words[1] ~= nil then -- ���� table �� ������
            local used_words = {} -- ������� ������ ��� ��� ��������� ����
            for k, v in pairs(words) do -- ������� �������
              if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
                message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
                used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
              end
            end
            used_words = nil -- ������� ������ �������������� ����
            message_on_chat_status = 1 -- ���������� ������ ��� ������ ���������� ���������
            sampSendChat(message) -- ������� ���
          else
            message_on_chat_status = 1 -- ...
            sampSendChat(message) -- ...
          end
        end,
        function(err) -- � ������ ������� ��� �������� � �������� �������
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
        end)
    end
    if settings.main.mode == 1 then -- ������ ������ �� ����� ��������� ���� status = 0
      if message_on_chat_status ~= 0 then
        message_on_chat_status = 0
      else
        return false
      end
    end
  end
end

function sampev.onSendCommand(command)
if settings.main.mode ~= 0 then
    typecommand, message = string.match(command, "/(%a+) (.+)")
    if typecommand ~= nil and message ~= nil then
      if message ~= "" and settings.main.mode == 3 then
        message = trim(message)
        if settings.main.auto_upper_and_point then
          local fist_symbol = string.sub(message, 1, 1) -- �������� ������ ������ �����
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- �������� ��������� ������ ������
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- ��������� ������ ������ � ������� �������
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- � ������ ���������� ��������� �����, ������ �����
        end
          local url_text = urlencode(message) -- ����������� ��������� � URL ������ 
          local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
          async_http_request("GET", url, nil, -- GET ������
          function(response) -- ���� ����� ������
            local words = decodeJson(response.text) -- ���������� JSON ����� � table
            if words[1] ~= nil then -- ���� table �� ������
              local used_words = {} -- ������� ������ ��� ��� ��������� ����
              currect_message = '' -- ������� ������ ���������� ��� ���������� � ��� ����������� ����
              currect_typecommand = typecommand
              for k, v in pairs(words) do -- ������� �������
                if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
                  --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
                  if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                  used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
                end
              end
              used_words = nil -- ������� ������ �������������� ����
              sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} ������� ������:{20B802}%s{FFFFFF}. ������� - \"F2\" ��� �����������", currect_message), -1)
            end
          end,
          function(err) -- � ������ ������� ��� �������� � �������� �������
            sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
          end)
      end
      if message ~= "" and settings.main.mode == 2 then
        message = trim(message)
          if settings.main.auto_upper_and_point then
          local fist_symbol = string.sub(message, 1, 1) -- �������� ������ ������ �����
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- �������� ��������� ������ ������
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- ��������� ������ ������ � ������� �������
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- � ������ ���������� ��������� �����, ������ �����
          end
          local url_text = urlencode(message) -- ����������� ��������� � URL ������ 
          local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
          async_http_request("GET", url, nil, -- GET ������
          function(response) -- ���� ����� ������
            local words = decodeJson(response.text) -- ���������� JSON ����� � table
            if words[1] ~= nil then -- ���� table �� ������
              local used_words = {} -- ������� ������ ��� ��� ��������� ����
              currect_message = '' -- ������� ������ ���������� ��� ���������� � ��� ����������� ����
              currect_typecommand = typecommand
              for k, v in pairs(words) do -- ������� �������
                if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
                  --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
                  if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                  used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
                end
              end
              used_words = nil -- ������� ������ �������������� ����
              sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} ������� ������:{20B802}%s{FFFFFF}. ������� - \"F2\" ��� ������", currect_message), -1)
            end
          end,
          function(err) -- � ������ ������� ��� �������� � �������� �������
            sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
          end)
      end
      if message ~= "" and message_on_chat_status == 0 and settings.main.mode == 1 then -- ��������� ��������� �� �������
          message = trim(message)
          if settings.main.auto_upper_and_point then
          local fist_symbol = string.sub(message, 1, 1) -- �������� ������ ������ �����
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- �������� ��������� ������ ������
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- ��������� ������ ������ � ������� �������
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- � ������ ���������� ��������� �����, ������ �����
          end
          local url_text = urlencode(message) -- ����������� ��������� � URL ������ 
          local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- ����������� ������ �� ������� �������(������������ ������)
          async_http_request("GET", url, nil, -- GET ������
          function(response) -- ���� ����� ������
            local words = decodeJson(response.text) -- ���������� JSON ����� � table
            if words[1] ~= nil then -- ���� table �� ������
              local used_words = {} -- ������� ������ ��� ��� ��������� ����
              for k, v in pairs(words) do -- ������� �������
                if used_words[u8:decode(v['word'])] == nil then -- ���� ������ ����� ��� �� ����������
                  message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- ������ ������ ������������� ����� ['word'] �� ���������� ['s']
                  used_words[u8:decode(v['word'])] = 1 -- ��������� ��� �������� ����� � ������ ��������� ����
                end
              end
              used_words = nil -- ������� ������ �������������� ����
              message_on_chat_status = 1 -- ���������� ������ ��� ������ ���������� ���������
              sampSendChat(string.format('/%s %s', typecommand, message)) -- ������� ���
            else
              message_on_chat_status = 1 -- ...
              sampSendChat(string.format('/%s %s', typecommand, message)) -- ...
            end
          end,
          function(err) -- � ������ ������� ��� �������� � �������� �������
            sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������ ��� ��������", -1)
          end)
      end
      if settings.main.mode == 1 then -- ������ ������ �� ����� ��������� ���� status = 0
        if message_on_chat_status ~= 0 then
          message_on_chat_status = 0
        else
          return false
        end
      end  
    end
  end
end

function settings_command(text)
  if text ~= '' then
    if text == '0' or text == '1' or text == '2' or text == '3' or text == '4' then
      if text ~= '4' then
        settings.main.mode = tonumber(text)
        sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} �� ���������� ���: "..text, -1)
      else
        if settings.main.auto_upper_and_point then
          settings.main.auto_upper_and_point = false
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} �� ��������� ����-����� � ����-��������� �����", -1)
        else
          settings.main.auto_upper_and_point = true
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} �� �������� ����-����� � ����-��������� �����", -1)
        end
      end
      inicfg.save(settings, 'CorrectionWords') 
    else
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ������: ������� ������ ��������", -1)  
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 0 - ��������� ������ | 1 - ��������������� ����� ����� �����������(�������� ��������)", -1) 
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 2 - ����������� ��������� ������ ��� ����� ����������� | 4 - ���������� ����������� �����", -1)   
    end
  else
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} /cwset [����� ���� 0, 1, 2, 3]", -1)  
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 0 - ��������� ������ | 1 - ��������������� ����� ����� �����������(�������� ��������)", -1) 
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 2 - ����������� ��������� ������ ��� ����� ����������� | 3 - ���������� ����������� �����", -1) 
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} {00AAFF}/cwset 4 {FFFFFF}- ���������/�������� ����-����� � ����-��������� �����", -1) 
  end
end

function hint_command()
  if settings.main.hint == 1 then
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ��������� ���� ���������", -1) 
    settings.main.hint = 0 
    inicfg.save(settings, 'CorrectionWords') 
  else
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ��������� ���� ��������", -1) 
    settings.main.hint = 1 
    inicfg.save(settings, 'CorrectionWords') 
  end
end

function checkdownload(id, status, p1, p2)
  sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} ���������� ���. ���������", -1) 
  if status == dlstatus.STATUS_ENDDOWNLOADDATA then
    reloadScript = true
    thisScript():reload()
  end
end

