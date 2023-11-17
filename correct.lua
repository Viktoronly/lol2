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

--no_symbol = {':', '.', '/', "\\", '!', '?', ',', '"', "'", '@', '#', '№', '$', ';', '%', '^', '*', '(', ')', '[', ']', '{', '}', '~', '`', '-', '_'}

local russian_characters = {
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
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
        elseif ch == 168 then -- Ё
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
        elseif ch == 184 then -- ё
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
  -- Проверки на включение сампа --

	while not isSampAvailable() do
		wait(0)
	end

  ---------------------------------
  sampRegisterChatCommand("checkw", check_command) -- Регаем команду для проверки слов
  sampRegisterChatCommand("cwset", settings_command) -- Регаем команду для настроки модов скрипта
  sampRegisterChatCommand("chint", hint_command) -- Убрать/Показать подсказку при входе в игру
  sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} by {00AAFF}R{FFFFFF}oyan {00AAFF}M{FFFFFF}illans", -1) -- Вывод авторского сообщения
  if settings.main.hint == 1 then
    sampAddChatMessage("{00AAFF}[CorrectionWords] /cwset{FFFFFF} - Настройки | {00AAFF}/checkw{FFFFFF} - Проверить слово/предложение", -1) -- Вывод авторского сообщения  
    sampAddChatMessage("{00AAFF}[CorrectionWords] CTRL + X{FFFFFF} - Исправить текст в открытом чате | {00AAFF}/chint{FFFFFF} - Убрать эту подсказку", -1) -- Вывод авторского сообщения  
  end
	while true do -- Бесконечный цикл
		wait(0)
    if isKeyDown(17) and isKeyJustPressed(88) and sampIsChatInputActive() then -- CTRL + X и открыт чат
      local message_user = sampGetChatInputText() -- Поучаем текст с чата(инпут)
      correctionInput(message_user) -- Отправляем его на функцию переработки
    end
    if isKeyDown(17) and isKeyJustPressed(90) and sampIsChatInputActive() and old_message ~= nil -- CTRL + Z, открыт чат и старое сообщение не пусто
    then
      sampSetChatInputText(old_message) -- Устанавливаем старое сообщение
      old_message = nil -- Обнуляем переменную
    end
    if isKeyJustPressed(113) and currect_message ~= nil then -- если нажал F2 и сообщения с исправлениями не пусто
      if settings.main.mode == 2 then 
        if currect_typecommand == nil then 
         sampSendChat(string.format('Кхе..%s.', currect_message)) 
        else
          sampSendChat(string.format('/%s Кхе..%s.', currect_typecommand, currect_message))  
          currect_typecommand = nil
        end
      end -- выводим это сообщение как - "Кхе.. [Ошибки]."
      if settings.main.mode == 3 then setClipboardText(currect_message) sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Исправленные слова скопированы", -1) end -- выводим это сообщение как - "Кхе.. [Ошибки]."
      currect_message = nil -- Обнуляем переменную
    end
	end
end

function check_command(text)
  if text ~= "" then -- Проверяем параметры на пустоту
    text = trim(text)
    if string.len(text) < 100 then -- Проверяем на величину параметра
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Производится проверка..", -1)
      local url_text = urlencode(text) -- Кодирование параметра в URL формат
      local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
      async_http_request("GET", url, nil, -- GET запрос
      function(response) -- Если ответ пришел
        local words = decodeJson(response.text) -- Декодируем JSON ответ в table
        if words[1] ~= nil then -- если table не пустая
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Найдены ошибки:", -1)
          local used_words = {} -- Создаем массив для уже замененых слов
          for k, v in pairs(words) do -- перебор массива
            if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
              text = text:gsub(u8:decode(v['word']), string.format("{20B802}%s{FFFFFF}", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
              used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
            end
          end
          used_words = nil -- Очищаем массив использованных слов
          sampAddChatMessage(text, -1) -- Выводим исправленный результат параметра
        else
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибок не найдено", -1)
        end
      end,
      function(err) -- В случае неудаче при передачи и принятии запроса
        sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
      end)
    else
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Слишком длинное предложение или слово", -1)  
    end
  else
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} /checkw [Слово/Предложение]", -1)  
  end
end

function correctionInput(message)
  if message ~= "" then -- Проверяем параметры на пустоту
      message = trim(message)
      if settings.main.auto_upper_and_point then
        local fist_symbol = string.sub(message, 1, 1) -- Получаем первый символ строк
        local last_symbol = string.sub(message, string.len(message), string.len(message)) -- Получаем последний символ строки
        message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- Переводим первый символ в верхний регистр
        if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- В случае отсутствия закрытого знака, ставим точку
        sampSetChatInputText(message)
      end
      local url_text = urlencode(message) -- Кодирование параметра в URL формат 
      local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
      async_http_request("GET", url, nil, -- GET запрос
      function(response) -- Если ответ пришел
        local words = decodeJson(response.text) -- Декодируем JSON ответ в table
        if words[1] ~= nil then -- если table не пустая
          old_message = message
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибки исправлены", -1)
          local used_words = {} -- Создаем массив для уже замененых слов
          for k, v in pairs(words) do -- перебор массива
            if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
              message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
              used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
            end
          end
          used_words = nil -- Очищаем массив использованных слов
          message = message:gsub('//', '/')
          sampSetChatInputText(message) -- Устанавливаем исправленный текст в input
        else
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибок не найдено", -1)
        end
      end,
      function(err) -- В случае неудаче при передачи и принятии запроса
        sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
      end)
  end
end

function sampev.onSendChat(message)
if settings.main.mode ~= 0 then
  if message ~= "" and settings.main.mode == 3 then
      message = trim(message)
      if settings.main.auto_upper_and_point then
        local fist_symbol = string.sub(message, 1, 1) -- Получаем первый символ строк
        local last_symbol = string.sub(message, string.len(message), string.len(message)) -- Получаем последний символ строки
        message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- Переводим первый символ в верхний регистр
        if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- В случае отсутствия закрытого знака, ставим точку
      end
        local url_text = urlencode(message) -- Кодирование параметра в URL формат 
        local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
        async_http_request("GET", url, nil, -- GET запрос
        function(response) -- Если ответ пришел
          local words = decodeJson(response.text) -- Декодируем JSON ответ в table
          if words[1] ~= nil then -- если table не пустая
            local used_words = {} -- Создаем массив для уже замененых слов
            currect_message = '' -- Создаем пустую переменную для содержания в ней исправленых слов
            currect_typecommand = nil
            for k, v in pairs(words) do -- перебор массива
              if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
                --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
                if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
              end
            end
            used_words = nil -- Очищаем массив использованных слов
            sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} Найдены ошибки:{20B802}%s{FFFFFF}. Нажмите - \"F2\" для копирования", currect_message), -1)
          end
        end,
        function(err) -- В случае неудаче при передачи и принятии запроса
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
        end)
    end
    if message ~= "" and settings.main.mode == 2 then
      message = trim(message)
        if settings.main.auto_upper_and_point then
        local fist_symbol = string.sub(message, 1, 1) -- Получаем первый символ строк
        local last_symbol = string.sub(message, string.len(message), string.len(message)) -- Получаем последний символ строки
        message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- Переводим первый символ в верхний регистр
        if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- В случае отсутствия закрытого знака, ставим точку
      end
        local url_text = urlencode(message) -- Кодирование параметра в URL формат 
        local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
        async_http_request("GET", url, nil, -- GET запрос
        function(response) -- Если ответ пришел
          local words = decodeJson(response.text) -- Декодируем JSON ответ в table
          if words[1] ~= nil then -- если table не пустая
            local used_words = {} -- Создаем массив для уже замененых слов
            currect_message = '' -- Создаем пустую переменную для содержания в ней исправленых слов
            currect_typecommand = nil
            for k, v in pairs(words) do -- перебор массива
              if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
                --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
                if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
              end
            end
            used_words = nil -- Очищаем массив использованных слов
            sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} Найдены ошибки:{20B802}%s{FFFFFF}. Нажмите - \"F2\" для вывода", currect_message), -1)
          end
        end,
        function(err) -- В случае неудаче при передачи и принятии запроса
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
        end)
    end
    if message ~= "" and message_on_chat_status == 0 and settings.main.mode == 1 then -- Проверяем параметры на пустоту
        message = trim(message)
        if settings.main.auto_upper_and_point then
          local fist_symbol = string.sub(message, 1, 1) -- Получаем первый символ строк
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- Получаем последний символ строки
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- Переводим первый символ в верхний регистр
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- В случае отсутствия закрытого знака, ставим точку
        end
        local url_text = urlencode(message) -- Кодирование параметра в URL формат 
        local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
        async_http_request("GET", url, nil, -- GET запрос
        function(response) -- Если ответ пришел
          local words = decodeJson(response.text) -- Декодируем JSON ответ в table
          if words[1] ~= nil then -- если table не пустая
            local used_words = {} -- Создаем массив для уже замененых слов
            for k, v in pairs(words) do -- перебор массива
              if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
                message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
                used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
              end
            end
            used_words = nil -- Очищаем массив использованных слов
            message_on_chat_status = 1 -- Выставляем статус для вывода следующего сообещния
            sampSendChat(message) -- выводим его
          else
            message_on_chat_status = 1 -- ...
            sampSendChat(message) -- ...
          end
        end,
        function(err) -- В случае неудаче при передачи и принятии запроса
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
        end)
    end
    if settings.main.mode == 1 then -- Ставим запрет на вывод сообщений если status = 0
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
          local fist_symbol = string.sub(message, 1, 1) -- Получаем первый символ строк
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- Получаем последний символ строки
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- Переводим первый символ в верхний регистр
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- В случае отсутствия закрытого знака, ставим точку
        end
          local url_text = urlencode(message) -- Кодирование параметра в URL формат 
          local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
          async_http_request("GET", url, nil, -- GET запрос
          function(response) -- Если ответ пришел
            local words = decodeJson(response.text) -- Декодируем JSON ответ в table
            if words[1] ~= nil then -- если table не пустая
              local used_words = {} -- Создаем массив для уже замененых слов
              currect_message = '' -- Создаем пустую переменную для содержания в ней исправленых слов
              currect_typecommand = typecommand
              for k, v in pairs(words) do -- перебор массива
                if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
                  --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
                  if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                  used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
                end
              end
              used_words = nil -- Очищаем массив использованных слов
              sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} Найдены ошибки:{20B802}%s{FFFFFF}. Нажмите - \"F2\" для копирования", currect_message), -1)
            end
          end,
          function(err) -- В случае неудаче при передачи и принятии запроса
            sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
          end)
      end
      if message ~= "" and settings.main.mode == 2 then
        message = trim(message)
          if settings.main.auto_upper_and_point then
          local fist_symbol = string.sub(message, 1, 1) -- Получаем первый символ строк
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- Получаем последний символ строки
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- Переводим первый символ в верхний регистр
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- В случае отсутствия закрытого знака, ставим точку
          end
          local url_text = urlencode(message) -- Кодирование параметра в URL формат 
          local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
          async_http_request("GET", url, nil, -- GET запрос
          function(response) -- Если ответ пришел
            local words = decodeJson(response.text) -- Декодируем JSON ответ в table
            if words[1] ~= nil then -- если table не пустая
              local used_words = {} -- Создаем массив для уже замененых слов
              currect_message = '' -- Создаем пустую переменную для содержания в ней исправленых слов
              currect_typecommand = typecommand
              for k, v in pairs(words) do -- перебор массива
                if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
                  --message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
                  if k == 1 then currect_message = string.format('%s %s', currect_message, u8:decode(v['s'][1])) else currect_message = string.format('%s, %s', currect_message, u8:decode(v['s'][1])) end
                  used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
                end
              end
              used_words = nil -- Очищаем массив использованных слов
              sampAddChatMessage(string.format("{00AAFF}[CorrectionWords]{FFFFFF} Найдены ошибки:{20B802}%s{FFFFFF}. Нажмите - \"F2\" для вывода", currect_message), -1)
            end
          end,
          function(err) -- В случае неудаче при передачи и принятии запроса
            sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
          end)
      end
      if message ~= "" and message_on_chat_status == 0 and settings.main.mode == 1 then -- Проверяем параметры на пустоту
          message = trim(message)
          if settings.main.auto_upper_and_point then
          local fist_symbol = string.sub(message, 1, 1) -- Получаем первый символ строк
          local last_symbol = string.sub(message, string.len(message), string.len(message)) -- Получаем последний символ строки
          message = string.rupper(fist_symbol)..string.sub(message, 2, string.len(message)) -- Переводим первый символ в верхний регистр
          if last_symbol ~= '.' and last_symbol ~= '!' and last_symbol ~= '?' and last_symbol ~= '...' and last_symbol ~= ':' then message = message..'.' end -- В случае отсутствия закрытого знака, ставим точку
          end
          local url_text = urlencode(message) -- Кодирование параметра в URL формат 
          local url = u8("https://speller.yandex.net/services/spellservice.json/checkText?text="..url_text) -- Отправление текста на спеллер яндекса(определитель ошибок)
          async_http_request("GET", url, nil, -- GET запрос
          function(response) -- Если ответ пришел
            local words = decodeJson(response.text) -- Декодируем JSON ответ в table
            if words[1] ~= nil then -- если table не пустая
              local used_words = {} -- Создаем массив для уже замененых слов
              for k, v in pairs(words) do -- перебор массива
                if used_words[u8:decode(v['word'])] == nil then -- Если данное слово еще не заменялось
                  message = message:gsub(u8:decode(v['word']), string.format("%s", u8:decode(v['s'][1]))) -- Делаем замену неправильного слова ['word'] на правильное ['s']
                  used_words[u8:decode(v['word'])] = 1 -- Добавляем уже заменное слово в массив замененых слов
                end
              end
              used_words = nil -- Очищаем массив использованных слов
              message_on_chat_status = 1 -- Выставляем статус для вывода следующего сообещния
              sampSendChat(string.format('/%s %s', typecommand, message)) -- выводим его
            else
              message_on_chat_status = 1 -- ...
              sampSendChat(string.format('/%s %s', typecommand, message)) -- ...
            end
          end,
          function(err) -- В случае неудаче при передачи и принятии запроса
            sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка при проверке", -1)
          end)
      end
      if settings.main.mode == 1 then -- Ставим запрет на вывод сообщений если status = 0
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
        sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Вы установили мод: "..text, -1)
      else
        if settings.main.auto_upper_and_point then
          settings.main.auto_upper_and_point = false
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Вы отключили авто-точки и авто-заглавные буквы", -1)
        else
          settings.main.auto_upper_and_point = true
          sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Вы включили авто-точки и авто-заглавные буквы", -1)
        end
      end
      inicfg.save(settings, 'CorrectionWords') 
    else
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Ошибка: неверно указан параметр", -1)  
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 0 - отключить скрипт | 1 - Автоисправление сразу после отправления(возможна задержка)", -1) 
      sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 2 - Предложение исправить ошибки уже после отправления | 4 - Копировать исправленые слова", -1)   
    end
  else
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} /cwset [Номер мода 0, 1, 2, 3]", -1)  
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 0 - отключить скрипт | 1 - Автоисправление сразу после отправления(возможна задержка)", -1) 
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} 2 - Предложение исправить ошибки уже после отправления | 3 - Копировать исправленые слова", -1) 
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} {00AAFF}/cwset 4 {FFFFFF}- Отключить/Включить авто-точки и авто-заглавные буквы", -1) 
  end
end

function hint_command()
  if settings.main.hint == 1 then
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Подсказка была отключена", -1) 
    settings.main.hint = 0 
    inicfg.save(settings, 'CorrectionWords') 
  else
    sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Подсказка была включена", -1) 
    settings.main.hint = 1 
    inicfg.save(settings, 'CorrectionWords') 
  end
end

function checkdownload(id, status, p1, p2)
  sampAddChatMessage("{00AAFF}[CorrectionWords]{FFFFFF} Скачивание доп. библиотек", -1) 
  if status == dlstatus.STATUS_ENDDOWNLOADDATA then
    reloadScript = true
    thisScript():reload()
  end
end

