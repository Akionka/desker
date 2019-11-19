script_name('Desker')
script_author('Akionka')
script_version('1.0.3')
script_version_number(4)
script_moonloader(27)

require 'deps' {
  'fyp:samp-lua',
  'fyp:moon-imgui',
  'Akionka:lua-semver',
}

local sampev           = require 'lib.samp.events'
local encoding         = require 'encoding'
local imgui            = require 'imgui'
local v                = require 'semver'

local updatesAvaliable = false
local lastTagAvaliable = '1.0'

encoding.default       = 'cp1251'
local u8               = encoding.UTF8

local prefix           = 'Checker'
local bindID           = 0

local serverIds = {
  ['185.169.134.84'] = 0,
  ['185.169.134.85'] = 1,
}

local data = {
  settings = {
    alwaysAutoCheckUpdates = true,
    alwaysAutoChangeDesc   = true,
    alwaysAutoUpdateDesc   = true,
    alwaysAutoAddDesc      = true,
  },
  accounts = {
    {
      nickname = 'Jacob_Spencer',
      serverId = serverIds['185.169.134.85'],
      desks = {
        {
          title = 'Test',
          text = 'Просто заполни меня',
          skinId = 0,
        },
      },
    },
  },
}

local tempBuffers   = {}
local loadedAccount = {}

function applyCustomStyle()
  imgui.SwitchContext()
  local style  = imgui.GetStyle()
  local colors = style.Colors
  local clr    = imgui.Col
  local function ImVec4(color)
    local r = bit.band(bit.rshift(color, 24), 0xFF)
    local g = bit.band(bit.rshift(color, 16), 0xFF)
    local b = bit.band(bit.rshift(color, 8), 0xFF)
    local a = bit.band(color, 0xFF)
    return imgui.ImVec4(r/255, g/255, b/255, a/255)
  end

  style['WindowRounding']      = 10.0
  style['WindowTitleAlign']    = imgui.ImVec2(0.5, 0.5)
  style['ChildWindowRounding'] = 5.0
  style['FrameRounding']       = 5.0
  style['ItemSpacing']         = imgui.ImVec2(5.0, 5.0)
  style['ScrollbarSize']       = 13.0
  style['ScrollbarRounding']   = 5

  colors[clr['Text']]                 = ImVec4(0xFFFFFFFF)
  colors[clr['TextDisabled']]         = ImVec4(0x212121FF)
  colors[clr['WindowBg']]             = ImVec4(0x212121FF)
  colors[clr['ChildWindowBg']]        = ImVec4(0x21212180)
  colors[clr['PopupBg']]              = ImVec4(0x212121FF)
  colors[clr['Border']]               = ImVec4(0xFFFFFF10)
  colors[clr['BorderShadow']]         = ImVec4(0x21212100)
  colors[clr['FrameBg']]              = ImVec4(0xC3E88D90)
  colors[clr['FrameBgHovered']]       = ImVec4(0xC3E88DFF)
  colors[clr['FrameBgActive']]        = ImVec4(0x61616150)
  colors[clr['TitleBg']]              = ImVec4(0x212121FF)
  colors[clr['TitleBgActive']]        = ImVec4(0x212121FF)
  colors[clr['TitleBgCollapsed']]     = ImVec4(0x212121FF)
  colors[clr['MenuBarBg']]            = ImVec4(0x21212180)
  colors[clr['ScrollbarBg']]          = ImVec4(0x212121FF)
  colors[clr['ScrollbarGrab']]        = ImVec4(0xEEFFFF20)
  colors[clr['ScrollbarGrabHovered']] = ImVec4(0xEEFFFF10)
  colors[clr['ScrollbarGrabActive']]  = ImVec4(0x80CBC4FF)
  colors[clr['ComboBg']]              = colors[clr['PopupBg']]
  colors[clr['CheckMark']]            = ImVec4(0x212121FF)
  colors[clr['SliderGrab']]           = ImVec4(0x212121FF)
  colors[clr['SliderGrabActive']]     = ImVec4(0x80CBC4FF)
  colors[clr['Button']]               = ImVec4(0xC3E88D90)
  colors[clr['ButtonHovered']]        = ImVec4(0xC3E88DFF)
  colors[clr['ButtonActive']]         = ImVec4(0x61616150)
  colors[clr['Header']]               = ImVec4(0x151515FF)
  colors[clr['HeaderHovered']]        = ImVec4(0x252525FF)
  colors[clr['HeaderActive']]         = ImVec4(0x303030FF)
  colors[clr['Separator']]            = colors[clr['Border']]
  colors[clr['SeparatorHovered']]     = ImVec4(0x212121FF)
  colors[clr['SeparatorActive']]      = ImVec4(0x212121FF)
  colors[clr['ResizeGrip']]           = ImVec4(0x212121FF)
  colors[clr['ResizeGripHovered']]    = ImVec4(0x212121FF)
  colors[clr['ResizeGripActive']]     = ImVec4(0x212121FF)
  colors[clr['CloseButton']]          = ImVec4(0x212121FF)
  colors[clr['CloseButtonHovered']]   = ImVec4(0xD41223FF)
  colors[clr['CloseButtonActive']]    = ImVec4(0xD41223FF)
  colors[clr['PlotLines']]            = ImVec4(0x212121FF)
  colors[clr['PlotLinesHovered']]     = ImVec4(0x212121FF)
  colors[clr['PlotHistogram']]        = ImVec4(0x212121FF)
  colors[clr['PlotHistogramHovered']] = ImVec4(0x212121FF)
  colors[clr['TextSelectedBg']]       = ImVec4(0x212121FF)
  colors[clr['ModalWindowDarkening']] = ImVec4(0x21212180)
end

local mainWindowState      = imgui.ImBool(false)
local skin_texture         = nil
local showErrorWrongSkinId = false

local selectedTab     = 0
local selectedAccount = 0
local selectedDesk    = 0

function imgui.OnDrawFrame()
  local function Color(color)
    local r = bit.band(bit.rshift(color, 24), 0xFF)
    local g = bit.band(bit.rshift(color, 16), 0xFF)
    local b = bit.band(bit.rshift(color, 8), 0xFF)
    local a = bit.band(color, 0xFF)
    return imgui.ImVec4(r/255, g/255, b/255, a/255)
  end
  if mainWindowState.v then
    local resX, resY = getScreenResolution()
    imgui.SetNextWindowSize(imgui.ImVec2(676, 350), 2)
    imgui.SetNextWindowPos(imgui.ImVec2(resX/2, resY/2), 2, imgui.ImVec2(0.5, 0.5))
    imgui.Begin('Desker v'..thisScript()['version'], mainWindowState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
    imgui.BeginGroup()
      imgui.BeginChild('Left panel', imgui.ImVec2(100, 0), true)
        if imgui.Selectable('Описания', selectedTab == 1) then selectedTab = 1 end
        if imgui.Selectable('Настройки', selectedTab == 2) then selectedTab = 2 end
        if imgui.Selectable('Информация', selectedTab == 3) then selectedTab = 3 end
      imgui.EndChild()
    imgui.EndGroup()
    imgui.SameLine()

    if selectedTab == 1 then
      imgui.BeginGroup()
        imgui.BeginChild('Accounts panel', imgui.ImVec2(145, -imgui.GetItemsLineHeightWithSpacing()), true)
          for i, v in ipairs(data['accounts']) do
            if imgui.Selectable((v['serverId'] == 1 and 'TRP2' or 'TRP1')..'|'..v['nickname']..'##'..i, selectedAccount == i, imgui.SelectableFlags.AllowDoubleClick) then
              tempBuffers['nickname'] = imgui.ImBuffer(v['nickname'], 32)
              tempBuffers['serverId'] = imgui.ImInt(v['serverId'])
              selectedAccount = i
              selectedDesk = 0
              if imgui.IsMouseDoubleClicked(0) then
                imgui.OpenPopup('Изменить данные аккаунта##'..i)
              end
            end
            if imgui.BeginPopupModal('Изменить данные аккаунта##'..i, nil, 64) then
              imgui.InputText('Ник-нейм', tempBuffers['nickname'])
              imgui.PushStyleColor(imgui.Col['Header'], Color(0xC3E88D90))
              imgui.PushStyleColor(imgui.Col['HeaderHovered'], Color(0xC3E88DFF))
              imgui.PushStyleColor(imgui.Col['HeaderActive'], Color(0x61616150))
              imgui.ListBox('Сервер', tempBuffers['serverId'], {'TRP1', 'TRP2'}, imgui.ImInt(2))
              imgui.PopStyleColor(3)
              imgui.Separator()
              imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
              if imgui.Button('Готово', imgui.ImVec2(120, 0)) then
                v['nickname'] = tempBuffers['nickname'].v
                v['serverId'] = tempBuffers['serverId'].v
                saveData()
                imgui.CloseCurrentPopup()
              end
              imgui.SameLine()
              if imgui.Button('Отмена', imgui.ImVec2(120, 0)) then imgui.CloseCurrentPopup() end
              imgui.EndPopup()
            end
          end
        imgui.EndChild()
        if imgui.Button('Добавить##account', imgui.ImVec2(selectedAccount == 0 and 145 or 70, 0)) then
          local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
          tempBuffers['nickname'] = imgui.ImBuffer(sampGetPlayerNickname(id), 32)
          tempBuffers['serverId'] = imgui.ImInt(serverIds[sampGetCurrentServerAddress()])
          imgui.OpenPopup('Добавление аккаунта')
        end
        imgui.SameLine()
        if selectedAccount ~= 0 and imgui.Button('Удалить##account', imgui.ImVec2(70, 0)) then
          imgui.OpenPopup('Удаление аккаунта')
        end

        if imgui.BeginPopupModal('Добавление аккаунта', nil, 64) then
          imgui.InputText('Ник-нейм', tempBuffers['nickname'])
          imgui.ListBox('Сервер', tempBuffers['serverId'], {'TRP1', 'TRP2'}, imgui.ImInt(2))
          imgui.Separator()
          imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
          if imgui.Button('Готово', imgui.ImVec2(120, 0)) then
            local denied   = false
            for i, v in ipairs(data['accounts']) do
              print(tempBuffers['nickname'].v, v['nickname'], tempBuffers['serverId'].v, v['serverId'])
              if tempBuffers['nickname'].v == v['nickname'] and tempBuffers['serverId'].v == v['serverId'] then
                denied = true
                break
              end
            end
            if not denied then
              table.insert(data['accounts'], {
                nickname = tempBuffers['nickname'].v,
                serverId = tempBuffers['serverId'].v,
                desks    = {},
              })
              saveData()
              imgui.CloseCurrentPopup()
            end
          end
          imgui.SameLine()
          if imgui.Button('Отмена', imgui.ImVec2(120, 0)) then
            imgui.CloseCurrentPopup()
          end
          imgui.EndPopup()
        end

        if imgui.BeginPopupModal('Удаление аккаунта', nil, 2) then
          imgui.Text('Удаление аккаунта приведет к полной потере всех данных, связанных с этим аккаунтов.\nЖелаете продолжить?')
          imgui.Separator()
          imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
          if imgui.Button('Да', imgui.ImVec2(120, 0)) then
            table.remove(data['accounts'], selectedAccount)
            selectedAccount = 0
            saveData()
            imgui.CloseCurrentPopup()
          end
          imgui.SameLine()
          if imgui.Button('Нет', imgui.ImVec2(120, 0)) then
            imgui.CloseCurrentPopup()
          end
          imgui.EndPopup()
        end
      imgui.EndGroup()
      imgui.SameLine()
        imgui.BeginGroup()
          imgui.BeginChild('Desks panel', imgui.ImVec2(145, -imgui.GetItemsLineHeightWithSpacing()), true)
            if selectedAccount ~= 0 then
              for i, v in ipairs(data['accounts'][selectedAccount]['desks']) do
                if imgui.Selectable(v['title']..'##'..i, selectedDesk == i) then
                  tempBuffers['title']  = imgui.ImBuffer(v['title'], 32)
                  tempBuffers['text']   = imgui.ImBuffer(v['text'], 256)
                  tempBuffers['skinId'] = imgui.ImInt(v['skinId'])
                  showErrorWrongSkinId = false
                  selectedDesk = i
                  skin_texture = imgui.CreateTextureFromFile(getGameDirectory()..'\\moonloader\\resource\\desker\\skins\\'..tempBuffers['skinId'].v..'.png')
                end
              end
            end
          imgui.EndChild()
          if selectedAccount ~= 0 and imgui.Button('Добавить##desk', imgui.ImVec2(145, 0)) then
            tempBuffers['titleCreate']  = imgui.ImBuffer('', 32)
            tempBuffers['textCreate']   = imgui.ImBuffer('', 256)
            tempBuffers['skinIdCreate'] = imgui.ImInt(getCharModel(PLAYER_PED))
            imgui.OpenPopup('Добавление описания')
          end

          if imgui.BeginPopupModal('Добавление описания', nil, 64) then
            imgui.InputText('Название', tempBuffers['titleCreate'])
            if imgui.InputInt('Скин', tempBuffers['skinIdCreate'], 1, 1) then
              if tempBuffers['skinIdCreate'].v > 311 then tempBuffers['skinIdCreate'].v = 311 end
              if tempBuffers['skinIdCreate'].v < 1 then tempBuffers['skinIdCreate'].v = 0 end
              skin_texture = imgui.CreateTextureFromFile(getWorkingDirectory()..'\\resource\\desker\\skins\\'..tempBuffers['skinIdCreate'].v..'.png')
            end
            if skin_texture and imgui.CollapsingHeader('Skin') then
              if tempBuffers['skinIdCreate'].v < 1 or tempBuffers['skinIdCreate'].v > 311 or tempBuffers['skinIdCreate'].v == 53 or tempBuffers['skinIdCreate'].v == 74 or tempBuffers['skinIdCreate'].v == 310 or tempBuffers['skinIdCreate'].v == 0 then
                imgui.Text('Не поддерживается')
              else
                imgui.Image(skin_texture, imgui.ImVec2(100, 100))
              end
            end
            imgui.InputTextMultiline('Описание', tempBuffers['textCreate'], imgui.ImVec2(0, 50))
            imgui.Separator()
            imgui.SetCursorPosX((imgui.GetWindowWidth() - 240 + imgui.GetStyle().ItemSpacing.x) / 2)
            if imgui.Button('Готово', imgui.ImVec2(120, 0)) then
              table.insert(data['accounts'][selectedAccount]['desks'], {
                title  = tempBuffers['titleCreate'].v,
                text   = tempBuffers['textCreate'].v,
                skinId = tempBuffers['skinIdCreate'].v,
              })
              saveData()
              imgui.CloseCurrentPopup()
            end
            imgui.SameLine()
            if imgui.Button('Отмена', imgui.ImVec2(120, 0)) then
              imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
          end
      imgui.EndGroup()
      imgui.SameLine()
        imgui.BeginGroup()
          imgui.BeginChild('Information panel', imgui.ImVec2(0,0), true)
            if selectedDesk ~= 0 and data['accounts'][selectedAccount]['desks'][selectedDesk] ~= nil then
              imgui.InputText('Название', tempBuffers['title'])
              if imgui.InputInt('Скин', tempBuffers['skinId'], 1, 1) then
                if tempBuffers['skinId'].v > 311 then tempBuffers['skinId'].v = 311 end
                if tempBuffers['skinId'].v < 1 then tempBuffers['skinId'].v = 0 end
                showErrorWrongSkinId = false
                for i, v in ipairs(data['accounts'][selectedAccount]['desks']) do
                  if tempBuffers['skinId'].v == v['skinId'] and tempBuffers['skinId'].v ~= data['accounts'][selectedAccount]['desks'][selectedDesk]['skinId'] then
                    showErrorWrongSkinId = true
                    break
                  end
                end
                skin_texture = imgui.CreateTextureFromFile(getWorkingDirectory()..'\\resource\\desker\\skins\\'..tempBuffers['skinId'].v..'.png')
              end
              if showErrorWrongSkinId then
                imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), 'Для данного скина уже установлено\nописание')
              end
              if skin_texture and imgui.CollapsingHeader('Skin') then
                if tempBuffers['skinId'].v < 1 or tempBuffers['skinId'].v > 311 or tempBuffers['skinId'].v == 53 or tempBuffers['skinId'].v == 74 or tempBuffers['skinId'].v == 310 or tempBuffers['skinId'].v == 0 then
                  imgui.Text('Не поддерживается')
                else
                  imgui.Image(skin_texture, imgui.ImVec2(100, 100))
                end
              end
              imgui.InputTextMultiline('Описание', tempBuffers['text'], imgui.ImVec2(0, 50))
              if imgui.Button('Сохранить', imgui.ImVec2(96.5, 0)) then
                local denied = false
                for i, v in ipairs(data['accounts'][selectedAccount]['desks']) do
                  if tempBuffers['skinId'].v == v['skinId'] and tempBuffers['skinId'].v ~= data['accounts'][selectedAccount]['desks'][selectedDesk]['skinId'] then
                    denied = true
                    break
                  end
                end
                if not denied then
                  data['accounts'][selectedAccount]['nickname']                      = tempBuffers['nickname'].v
                  data['accounts'][selectedAccount]['serverId']                      = tempBuffers['serverId'].v
                  data['accounts'][selectedAccount]['desks'][selectedDesk]['title']  = tempBuffers['title'].v
                  data['accounts'][selectedAccount]['desks'][selectedDesk]['text']   = tempBuffers['text'].v
                  data['accounts'][selectedAccount]['desks'][selectedDesk]['skinId'] = tempBuffers['skinId'].v
                end
                saveData()
              end
              imgui.SameLine()
              if imgui.Button('Удалить##desk', imgui.ImVec2(96.5, 0)) then
                table.remove(data['accounts'][selectedAccount]['desks'], selectedDesk)
                selectedDesk = selectedDesk - 1
                if selectedDesk ~= 0 then
                  tempBuffers['title'].v  = data['accounts'][selectedAccount]['desks'][selectedDesk]['title']
                end
                saveData()
              end
              if imgui.Button('Применить', imgui.ImVec2(198, 0)) then
                sampSendChat('/desk clear')
                sampSendChat(u8:decode('/desk '..data['accounts'][selectedAccount]['desks'][selectedDesk]['text']))
              end
            end
          imgui.EndChild()
      imgui.EndGroup()
    elseif selectedTab == 2 then
      imgui.BeginGroup()
        imgui.PushItemWidth(100)
        if imgui.Checkbox('Автоматически менять описание при смене скина', imgui.ImBool(data['settings']['alwaysAutoChangeDesc'])) then
          data['settings']['alwaysAutoChangeDesc'] = not data['settings']['alwaysAutoChangeDesc']
          saveData()
        end
        if imgui.Checkbox('Всегда автоматически подменять описание в базе при вводе /desc', imgui.ImBool(data['settings']['alwaysAutoUpdateDesc'])) then
          data['settings']['alwaysAutoUpdateDesc'] = not data['settings']['alwaysAutoUpdateDesc']
          saveData()
        end
        if imgui.Checkbox('Всегда автоматически добавлять описание в базу при вводе /desc', imgui.ImBool(data['settings']['alwaysAutoAddDesc'])) then
          data['settings']['alwaysAutoAddDesc'] = not data['settings']['alwaysAutoAddDesc']
          saveData()
        end
        if imgui.Checkbox('Всегда автоматически проверять обновления', imgui.ImBool(data['settings']['alwaysAutoCheckUpdates'])) then
          data['settings']['alwaysAutoCheckUpdates'] = not data['settings']['alwaysAutoCheckUpdates']
          saveData()
        end
        imgui.PopItemWidth()
      imgui.EndGroup()
    elseif selectedTab == 3 then
      imgui.BeginGroup()
        imgui.BeginChild('Center panel')
          imgui.Text('Название: Desker')
          imgui.Text('Автор: Akionka')
          imgui.Text('Версия: '..thisScript()['version_num']..' ('..thisScript()['version']..')')
          imgui.Text('Команды: /desker, /descer')
          if updatesAvaliable then
            if imgui.Button('Скачать обновление', imgui.ImVec2(150, 0)) then
              update()
              mainWindowState.v = false
            end
          else
            if imgui.Button('Проверить обновления', imgui.ImVec2(150, 0)) then
              checkUpdates()
            end
          end
          imgui.SameLine()
          if imgui.Button('Группа ВКонтакте', imgui.ImVec2(150, 0)) then os.execute('explorer "https://vk.com/akionkamods"') end
          if imgui.Button('Bug report [VK]', imgui.ImVec2(150, 0)) then os.execute('explorer "https://vk.com/akionka"') end
          imgui.SameLine()
          if imgui.Button('Bug report [Telegram]', imgui.ImVec2(150, 0)) then os.execute('explorer "https://teleg.run/akionka"') end
        imgui.EndChild()
      imgui.EndGroup()
    end
    imgui.End()
  end
end

function sampev.onSetPlayerSkin(playerId, skin)
  if not data['settings']['alwaysAutoUpdateDesc'] then return end
  local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
  if playerId == id then
    for i, v in ipairs(loadedAccount['desks']) do
      if v['skinId'] == skin then
        sampSendChat(u8:decode('/desk clear'))
        sampSendChat(u8:decode('/desk '..v['text']))
        setPlayerModel(PLAYER_HANDLE, skin)
      end
    end
  end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
  if id == 45 and text:find(u8:decode('Текст с описанием вашего персонажа был успешно удален.')) then
    return false
  end
  if id == 45 and title:find(u8:decode('Текст с описанием установлен:')) then
    sampSendDialogResponse(id, 1, 0, '')
    return false
  end
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(0) end
  if not doesDirectoryExist(getWorkingDirectory()..'\\config') then createDirectory(getWorkingDirectory()..'\\config') end
  if not doesDirectoryExist(getWorkingDirectory()..'\\resource\\desker\\skins\\') then createDirectory(getWorkingDirectory()..'\\resource\\desker\\skins\\') end

  local ip, port = sampGetCurrentServerAddress()
  if serverIds[ip] == nil then
    print(u8:decode('{FFFFFF}Скрипт поддерживает только Trintiy Roleplay 1 & Trinity Roleplay 2'))
    thisScript():unload()
  end

  loadData()
  loadAccount()
  applyCustomStyle()

  for i = 1, 311 do
    if i ~= 74 and i ~= 310 and i ~= 53 then
      lua_thread.create(function()
        local file = getWorkingDirectory()..'\\resource\\desker\\skins\\'..i..'.png'
        if not doesFileExist(file) then
          downloadUrlToFile('https://files.advance-rp.ru/media/skins/'..i..'.png', file, function() end)
        end
      end)
    end
  end

  print(u8:decode('{FFFFFF}Скрипт успешно загружен.'))
  print(u8:decode('{FFFFFF}Версия: {9932cc}'..thisScript()['version']..'{FFFFFF}. Автор: {9932cc}Akionka{FFFFFF}.'))
  print(u8:decode('{FFFFFF}Приятного использования! :)'))

  if data['settings']['alwaysAutoCheckUpdates'] then checkUpdates() end

  sampRegisterChatCommand('desker', desker)
  sampRegisterChatCommand('descer', desker)
  sampRegisterChatCommand('desk', desk)
  sampRegisterChatCommand('desc', desk)

  while true do
    wait(0)
    imgui.Process = mainWindowState.v
  end
end

function desker()
  mainWindowState.v = not mainWindowState.v
end

function desk(params)
  params = trim(params)
  local ip, port = sampGetCurrentServerAddress()
  if params:upper() == 'CLEAR' or params == '' then return end
  if loadedAccount == {} then
    if not data['settings']['alwaysAutoAddDesc'] then return end
    table.insert(data['accounts'], {
      nickname = 'Jacob_Spencer',
      serverId = serverIds[ip],
      desks = {
        {
          title  = 'Заполни',
          text   = u8: encode(params),
          skinId = getCharModel(PLAYER_PED),
        }}
      })
      saveData()
      loadAccount()
  else
    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local ip, port = sampGetCurrentServerAddress()
    local nickname = sampGetPlayerNickname(id)
    for i1, v1 in ipairs(data['accounts']) do
      if v1['nickname'] == nickname and v1['serverId'] == serverIds[ip] then
        for i2, v2 in ipairs(v1['desks']) do
          if not data['settings']['alwaysAutoUpdateDesc'] then return end
          if v2['skinId'] == getCharModel(PLAYER_PED) then
            v2['text'] = u8:encode(params)
            saveData()
            loadAccount()
            return
          end
        end
        if not data['settings']['alwaysAutoAddDesc'] then return end
        table.insert(v1['desks'], {
          title  = 'Заполни',
          text   = u8: encode(params),
          skinId = getCharModel(PLAYER_PED),
        })
        return
      end
    end
  end
end

function checkUpdates()
  local fpath = os.tmpname()
  if doesFileExist(fpath) then os.remove(fpath) end
  downloadUrlToFile('https://api.github.com/repos/akionka/'..thisScript()['name']..'/releases', fpath, function(_, status, _, _)
    if status == 58 then
      if doesFileExist(fpath) then
        local f = io.open(fpath, 'r')
        if f then
          local info = decodeJson(f: read('*a'))
          f:close()
          os.remove(fpath)
          if v(info[1]['tag_name']) > v(thisScript()['version']) then
            updatesAvaliable = true
            lastTagAvaliable = info[1]['tag_name']
            alert('Найдено объявление. Текущая версия: {9932cc}'..thisScript()['version']..'{FFFFFF}, новая версия: {9932cc}'..info[1]['tag_name']..'{FFFFFF}')
            return true
          else
            updatesAvaliable = false
            alert('У вас установлена самая свежая версия скрипта.')
          end
        else
          updatesAvaliable = false
          alert('Что-то пошло не так, упс. Попробуйте позже.')
        end
      end
    end
  end)
end

function update()
  downloadUrlToFile('https://github.com/akionka/'..thisScript()['name']..'/releases/download/'..lastTagAvaliable..'/desker.lua', thisScript()['path'], function(_, status, _, _)
    if status == 6 then
      alert('Новая версия установлена! Чтобы скрипт обновился нужно либо перезайти в игру, либо ...')
      alert('... если у вас есть автоперезагрузка скриптов, то новая версия уже готова и снизу вы увидите приветственное сообщение.')
      alert('Если что-то пошло не так, то сообщите мне об этом в VK или Telegram > {2980b0}vk.com/akionka teleg.run/akionka{FFFFFF}.')
      thisScript()['reload']()
    end
  end)
end

function alert(text)
  sampAddChatMessage(u8:decode('['..prefix..']: '..text), -1)
end

function saveData()
  local configFile = io.open(getWorkingDirectory()..'\\config\\desker.json', 'w+')
  configFile:write(encodeJson(data))
  configFile:close()
end

function loadData()
  local function loadSettings(table, dest)
    for k, v in pairs(table) do
      if type(v) == 'table' then
        loadSettings(v, dest[k])
      end
      dest[k] = v
    end
  end

  if not doesFileExist(getWorkingDirectory()..'\\config\\desker.json') then
    local configFile = io.open(getWorkingDirectory()..'\\config\\desker.json', 'w+')
    configFile:write(encodeJson(data))
    configFile:close()
    return
  end

  local configFile = io.open(getWorkingDirectory()..'\\config\\desker.json', 'r')
  local tempData = decodeJson(configFile:read('*a'))
  loadSettings(tempData['settings'], data['settings'])
  data['accounts'] = tempData['accounts']
  configFile:close()
end

function loadAccount()
  local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
  local ip, port = sampGetCurrentServerAddress()
  local nickname = sampGetPlayerNickname(id)
  for i, v in ipairs(data['accounts']) do
    if v['nickname'] == nickname and v['serverId'] == serverIds[ip] then
      loadedAccount = v
      break
    end
  end
end

function trim(s)
  return (string.gsub(s, '^%s*(.-)%s*$', '%1'))
end