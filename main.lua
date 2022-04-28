--[[
	Name: HONEY_MAKER
	Author: ParSec
	Version: 2.2.0
--]]

--[[
====================================================================================================================
	Variables
====================================================================================================================
--]]
local botVersion = '2.2.0'
local discordia = require('discordia')
local config_file = require('./config.lua')
local fs = require('fs')
local bot_desc = config_file.bot_description
local uv = require('uv')
local json = require('json')
local math = math
local next = next
discordia.extensions()
local client = discordia.Client()
local dataFile = config_file.data_file
local dataTable = {}
local commandsPrefix = config_file.command_prefix
local commandsTable = {}

local defaultData = {
	modules = {},
	settings = {},
	userBlacklist = {},
	channelWhitelist = {}
}

if not fs.existsSync('logs') then
	fs.mkdirSync('logs')
end

local pslog = discordia.Logger(3, '%Y-%m-%d %H:%M:%S', 'logs/' .. os.date('%Y-%m-%d_%H-%M-%S') .. '.log')

--[[
====================================================================================================================
	Functions
====================================================================================================================
--]]
--@ Creates timer runs it once and executes callback function
local function simpleTimer(timeout, callback, callbackArguments)
	if type(timeout) ~= 'number' or timeout < 0 or type(callback) ~= 'function' or type(callbackArguments) ~= 'table' then return end
	local timer = uv.new_timer()
	local function onTimeout()
		uv.timer_stop(timer)
		uv.close(timer)
		callback(callbackArguments)
	end
	uv.timer_start(timer, timeout, 0, onTimeout)
end

--@ Checks if table is empty
local function tableIsEmpty(tbl)
	if type(tbl) ~= 'table' then return false end
	if next(tbl) == nil then
		return true
	end
	return false
end

--@ Converts string or number to boolean
local function toBool(snIn)
	if type(snIn) == 'string' and #snIn > 0 then
		local stringToBool = {
			['true'] = true,
			['false'] = false
		}
		return stringToBool[snIn] or nil
	end

	if type(snIn) == 'number' then
		if snIn > 0 then
			return true
		else
			return false
		end
	end

	return nil
end

--@ Function for parsing duration into string
local function parseDuration(timeInt)
	if type(timeInt) ~= 'number' then return '00h 00min 00s' end
	timeInt = math.abs(timeInt)
	local fHours = math.floor(timeInt / 3600)
	timeInt = timeInt - (fHours * 3600)
	local fMinutes = math.floor(timeInt / 60)
	timeInt = timeInt - (fMinutes * 60)
	local fSeconds = math.floor(timeInt)

	return string.format('%02uh %02umin %02us', fHours, fMinutes, fSeconds)
end

--@ Creates module table
local function createModule(name, desc, defaultState)
	if type(name) ~= 'string' or #name <= 0 or type(desc) ~= 'string' or #desc <= 0 or type(defaultState) ~= 'boolean' then return end
	if defaultData.modules[name:lower()] then return end

	defaultData.modules[name:lower()] = {
		state = defaultState,
		description = desc,
		data = {}
	}
end

--@ Gets module state
local function getModuleState(guildID, name)
	if type(guildID) ~= 'string' or #guildID <= 0 or type(name) ~= 'string' or #name <= 0 then return false end
	if not defaultData.modules[name:lower()] then return false end
	if not dataTable[guildID].modules[name:lower()] then return false end

	return dataTable[guildID].modules[name:lower()].state
end

--@ Gets module data
local function getModuleData(guildID, name)
	if type(guildID) ~= 'string' or #guildID <= 0 or type(name) ~= 'string' or #name <= 0 then return {} end
	if not defaultData.modules[name:lower()] then return {} end
	if not dataTable[guildID].modules[name:lower()] then return {} end

	return dataTable[guildID].modules[name:lower()].data
end

--@ Creates setting table
local function createSetting(name, desc, defaultState)
	if type(name) ~= 'string' or #name <= 0 or type(desc) ~= 'string' or #desc <= 0 or type(defaultState) ~= 'boolean' then return end
	if defaultData.settings[name:lower()] then return end

	defaultData.settings[name:lower()] = {
		state = defaultState,
		description = desc
	}
end

--@ Gets setting state
local function getSettingState(guildID, name)
	if type(guildID) ~= 'string' or #guildID <= 0 or type(name) ~= 'string' or #name <= 0 then return false end
	if not defaultData.settings[name:lower()] then return false end
	if not dataTable[guildID].settings[name:lower()] then return false end

	return dataTable[guildID].settings[name:lower()].state
end

--@ Reads data stored in the file
local function readData()
	local f = io.open(dataFile, 'r')
	if not f then return false end
	local fileContent = f:read('*all')
	f:close()

	dataTable = json.parse(fileContent)
	return true
end

readData()

--@ Writes data into a file
local function writeData()
	local f = io.open(dataFile, 'w')
	if not f then return false end
	local fileContent = json.stringify(dataTable)
	f:write(fileContent)
	f:close()
	return true
end

--@ Function for creating commands
local function createCommand(name, cb, moduleN)
	if type(name) ~= 'string' or #name <= 0 or type(cb) ~= 'function' then return end
	if commandsTable[name:lower()] then return end

	if not moduleN or not defaultData.modules[moduleN] then moduleN = nil end

	name = name:lower()
	name = name:gsub('%s+', '_')
	name = name:gsub('^(_)', '')
	name = name:gsub('(_)$', '')

	commandsTable[name:lower()] = {
		callback = cb,
		moduleName = moduleN
	}

	return true
end

--@ Function to generate random string
local function generateRandomString(len, incN, incAC)
	if type(len) ~= 'number' or len < 1 or type(incN) ~= 'boolean' or type(incAC) ~= 'boolean' then return end

	local baseCharset = {}

	for i = 65, 90 do table.insert(baseCharset, string.char(i)) end
	for i = 97, 122 do table.insert(baseCharset, string.char(i)) end
	if incN then for i = 48, 57 do table.insert(baseCharset, string.char(i)) end end
	if incAC then
		for i = 33, 47 do table.insert(baseCharset, string.char(i)) end
		for i = 58, 64 do table.insert(baseCharset, string.char(i)) end
		for i = 91, 96 do table.insert(baseCharset, string.char(i)) end
		for i = 123, 126 do table.insert(baseCharset, string.char(i)) end
	end

	math.randomseed(os.time())

	local randomCharset = {}

	for _ = 1, #baseCharset do
		local tempKey = math.random(1, #baseCharset)
		table.insert(randomCharset, baseCharset[tempKey])
		table.remove(baseCharset, tempKey)
	end

	baseCharset = nil
	local returnString = ''

	for _ = 1, len do
		returnString = returnString .. randomCharset[math.random(1, #randomCharset)]
	end

	return returnString
end

--[[
====================================================================================================================
	Settings declaration
====================================================================================================================
--]]
createSetting('enable_channel_whitelist', 'Whitelist of channels for bot, so it doesn\'t spam', false)

--[[
====================================================================================================================
	Modules declaration
====================================================================================================================
--]]
createModule('darkchat', 'Adds roleplay darkchat capabilities to your discord', false)
createModule('business', 'Roleplay utilities to help you manage your business', false)

--[[
====================================================================================================================
	Commands declaration
====================================================================================================================
--]]
--@ Ping command
createCommand('ping', function(msg)
	msg.channel:send('Pong!')
end)

--@ Info command
createCommand('info', function(msg)
	msg.channel:send({embed = {
		title = 'About',
		description = 'Bot created for no fucking reason. It is as pointless as y\'all\'s lives.\nNow go fuck yaself, ya fuckwits!',
		author = {
			name = client.user.username .. ' by ParSec',
			icon_url = client.user.avatarURL
		},
		fields = {
			{
				name = 'Version',
				value = botVersion,
				inline = true
			},
			{
				name = 'Author',
				value = 'ParSec',
				inline = true
			}
		},
		footer = {
			text = 'Copyright © ' .. os.date('%Y') .. ' ParSec. All Rights Reserved.'
		},
		color = 0xe6e6e6
	}})
end)

--@ Command and subcommands for darkchat
createCommand('darkchat', function(msg, args)
	if not msg.member:hasPermission(0x00000008) then return end

	if args[1]:lower() == 'add' and #msg.mentionedChannels > 0 and '<#' .. msg.mentionedChannels:toArray()[1].id .. '>' == args[2]:lower() then
		dataTable[msg.guild.id].modules.darkchat.data[msg.mentionedChannels:toArray()[1].id] = true

		msg.channel:send('Successfuly converted "' .. msg.mentionedChannels:toArray()[1].name .. '" into darkchat channel.')
	end

	if args[1]:lower() == 'remove' and #msg.mentionedChannels > 0 and '<#' .. msg.mentionedChannels:toArray()[1].id .. '>' == args[2]:lower() and dataTable[msg.guild.id].modules.darkchat.data[msg.mentionedChannels:toArray()[1].id] then
		dataTable[msg.guild.id].modules.darkchat.data[msg.mentionedChannels:toArray()[1].id] = nil

		msg.channel:send('Successfuly converted "' .. msg.mentionedChannels:toArray()[1].name .. '" back to normal channel.')
	end

	writeData()
end, 'darkchat')

--@ Command for managing settings
createCommand('settings', function(msg, args)
	if not msg.member:hasPermission(0x00000008) then return end

	if #args >= 3 and args[2]:lower() == 'set' and (args[3]:lower() == 'true' or args[3] == 'false') and dataTable[msg.guild.id].settings[args[1]:lower()] then
		dataTable[msg.guild.id].settings[args[1]:lower()].state = toBool(args[3]:lower())
		msg.channel:send('Setting value successfuly changed!')

		writeData()
	elseif args[1]:lower() == '*' and args[2]:lower() == 'show' then
		local printTable = {}

		for k, v in pairs(dataTable[msg.guild.id].settings) do
			table.insert(printTable, '**' .. k .. '** is set to **' .. tostring(v.state) .. '**')
		end

		msg.channel:send(table.concat(printTable, '\n'))
	else
		msg.channel:send('Something went wrong!')
	end
end)

--@ Command for enabling/disabling modules for each server
createCommand('modules', function(msg, args)
	if msg.author.id ~= client.owner.id then return end

	if args[1]:lower() == 'enable' and #args[2] > 0 then
		dataTable[msg.guild.id].modules[args[2]:lower()].state = true
		msg.channel:send('Successfuly enabled "' .. args[2]:lower() .. '"')
	elseif args[1]:lower() == 'disable' and #args[2] > 0 then
		dataTable[msg.guild.id].modules[args[2]:lower()].state = false

		msg.channel:send('Successfuly disabled "' .. args[2]:lower() .. '"')
	end

	writeData()
end)

--@ Command to blacklist users from using the bot
createCommand('blacklist', function(msg, args)
	if msg.author.id ~= client.owner.id then return end

	if args[1]:lower() == 'add' and #msg.mentionedUsers > 0 and '<@!' .. msg.mentionedUsers:toArray()[1].id .. '>' == args[2]:lower() and not dataTable[msg.guild.id].userBlacklist[msg.mentionedUsers:toArray()[1].id] then
		dataTable[msg.guild.id].userBlacklist[msg.mentionedUsers:toArray()[1].id] = true
		msg.channel:send(msg.mentionedUsers:toArray()[1].tag .. ' has been added to blacklist')
	elseif args[1]:lower() == 'remove' and #msg.mentionedUsers > 0 and '<@!' .. msg.mentionedUsers:toArray()[1].id .. '>' == args[2]:lower() and dataTable[msg.guild.id].userBlacklist[msg.mentionedUsers:toArray()[1].id] then
		dataTable[msg.guild.id].userBlacklist[msg.mentionedUsers:toArray()[1].id] = nil
		msg.channel:send(msg.mentionedUsers:toArray()[1].tag .. ' has been removed from blacklist')
	elseif args[1]:lower() == 'list' and not tableIsEmpty(dataTable[msg.guild.id].userBlacklist) then
		local printTable = ''
		for k in pairs(dataTable[msg.guild.id].userBlacklist) do table.insert(printTable, k) end
		msg.channel:send(table.concat(printTable, '\n'))
	else
		msg.channel:send('Something went wrong!')
	end

	writeData()
end)

--@ Command to whitelist/blacklist channels so that bot doesn't repond everywhere
createCommand('whitelist', function(msg, args)
	if not msg.member:hasPermission(0x00000008) then return end

	if args[1]:lower() == 'add' and #msg.mentionedChannels > 0 and '<#' .. msg.mentionedChannels:toArray()[1].id .. '>' == args[2]:lower() then
		dataTable[msg.guild.id].channelWhitelist[msg.mentionedChannels:toArray()[1].id] = true

		msg.channel:send('Successfuly added "' .. msg.mentionedChannels:toArray()[1].name .. '" into channels whitelist.')
	end

	if args[1]:lower() == 'remove' and #msg.mentionedChannels > 0 and '<#' .. msg.mentionedChannels:toArray()[1].id .. '>' == args[2]:lower() and dataTable[msg.guild.id].channelWhitelist[msg.mentionedChannels:toArray()[1].id] then
		dataTable[msg.guild.id].channelWhitelist[msg.mentionedChannels:toArray()[1].id] = nil

		msg.channel:send('Successfuly removed "' .. msg.mentionedChannels:toArray()[1].name .. '" from channels whitelist.')
	end

	if args[1]:lower() == 'list' and not tableIsEmpty(dataTable[msg.guild.id].channelWhitelist) then
		local printTable = {}

		for x in pairs(dataTable[msg.guild.id].channelWhitelist) do
			local tempChannel = msg.guild:getChannel(x)
			local insertString = '(' .. tempChannel.id .. ') | ' .. tempChannel.name

			table.insert(printTable, insertString)
		end

		msg.channel:send(table.concat(printTable, '\n'))
	end

	writeData()
end)

--@ Command for managing business module
createCommand('business', function(msg, args)
	if args[1]:lower() == 'set' then
		if args[2]:lower() == 'owner' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@!' .. msg.mentionedUsers:toArray()[1].id .. '>' == args[4]:lower() and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner == msg.author.id and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id] then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner = msg.mentionedUsers:toArray()[1].id
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id].hr = true
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.author.id].hr = false

			msg.channel:send('Successfuly transfered ownership of "' .. args[3]:lower() .. '" to <@!' .. msg.mentionedUsers:toArray()[1].id .. '>')

			writeData()
		elseif args[2]:lower() == 'wage' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@&' .. msg.mentionedRoles:toArray()[1].id .. '>' == args[4]:lower() and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[msg.mentionedRoles:toArray()[1].id] and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner == msg.author.id and #args[5] > 0 and tonumber(args[5]) then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[msg.mentionedRoles:toArray()[1].id].wage = math.abs(tonumber(args[5]))

			msg.channel:send('Successfuly changed wage of <@&' .. msg.mentionedRoles:toArray()[1].id .. '> to $' .. math.abs(tonumber(args[5])) .. ' in "' .. args[3]:lower() .. '"')

			writeData()
		elseif args[2]:lower() == 'shifts_output_channel' and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<#' .. msg.mentionedChannels:toArray()[1].id .. '>' == args[4]:lower() and msg.author.id == dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].shifts_output_channel = msg.mentionedChannels:toArray()[1].id

			msg.channel:send('Successfuly set <#' .. msg.mentionedChannels:toArray()[1].id .. '> as shifts logs for "' .. args[3]:lower() .. '"')

			writeData()
		else
			msg.channel:send('Something went wrong!')
		end
	elseif args[1]:lower() == 'add' then
		if args[2]:lower() == 'business' and #args[3]:lower() >= 3 and not dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and msg.member:hasPermission(0x00000008) then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()] = {
				owner = msg.author.id,
				employees = {
					[msg.author.id] = {
						hr = true,
						shifts = {}
					},
				},
				positions = {}
			}

			msg.channel:send('Successfuly created business "' .. args[3]:lower() .. '"')

			writeData()
		elseif args[2]:lower() == 'hr' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@!' .. msg.mentionedUsers:toArray()[1].id .. '>' == args[4]:lower() and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner == msg.author.id and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id] and not dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id].hr then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id].hr = true

			msg.channel:send('Successfuly gave <@!' .. msg.mentionedUsers:toArray()[1].id .. '> HR')

			writeData()
		elseif args[2]:lower() == 'employee' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@!' .. msg.mentionedUsers:toArray()[1].id .. '>' == args[4]:lower() and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.author.id].hr and not dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id] then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id] = {
				hr = false,
				shifts = {}
			}

			msg.channel:send('Successfuly hired <@!' .. msg.mentionedUsers:toArray()[1].id .. '> in "' .. args[3]:lower() .. '"')

			writeData()
		elseif args[2]:lower() == 'position' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@&' .. msg.mentionedRoles:toArray()[1].id .. '>' == args[4]:lower() and not dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[msg.mentionedRoles:toArray()[1].id] and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner == msg.author.id then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[msg.mentionedRoles:toArray()[1].id] = {
				wage = 0
			}

			msg.channel:send('Added <@&' .. msg.mentionedRoles:toArray()[1].id .. '> to "' .. args[3]:lower() .. '" as position')

			writeData()
		else
			msg.channel:send('Something went wrong!')
		end
	elseif args[1]:lower() == 'remove' then
		if args[2]:lower() == 'business' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and msg.member:hasPermission(0x00000008) then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()] = nil

			msg.channel:send('Successfuly removed business "' .. args[3]:lower() .. '"')

			writeData()
		elseif args[2]:lower() == 'hr' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@!' .. msg.mentionedUsers:toArray()[1].id .. '>' == args[4]:lower() and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner == msg.author.id and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id] and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id].hr then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id].hr = false

			msg.channel:send('Successfuly took HR from <@!' .. msg.mentionedUsers:toArray()[1].id .. '>')

			writeData()
		elseif args[2]:lower() == 'employee' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@!' .. msg.mentionedUsers:toArray()[1].id .. '>' == args[4]:lower() and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.author.id].hr and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id] and msg.mentionedUsers:toArray()[1].id ~= dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[msg.mentionedUsers:toArray()[1].id] = nil

			msg.channel:send('Successfuly fired <@!' .. msg.mentionedUsers:toArray()[1].id .. '> from "' .. args[3]:lower() .. '"')

			writeData()
		elseif args[2]:lower() == 'position' and #args[3]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and '<@&' .. msg.mentionedRoles:toArray()[1].id .. '>' == args[4]:lower() and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[msg.mentionedRoles:toArray()[1].id] and dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner == msg.author.id then
			dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[msg.mentionedRoles:toArray()[1].id] = nil

			msg.channel:send('Removed <@&' .. msg.mentionedRoles:toArray()[1].id .. '> from "' .. args[3]:lower() .. '" as position')

			writeData()

		else
			msg.channel:send('Something went wrong!')
		end
	elseif args[1]:lower() == 'calculate' and args[2]:lower() == 'paychecks' and dataTable[msg.guild.id].modules.business.data[args[3]:lower()] and not tableIsEmpty(dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions) and msg.author.id == dataTable[msg.guild.id].modules.business.data[args[3]:lower()].owner then
		msg.channel:send('@everyone closing system!')
		for uid, employee in pairs(dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees) do
			if #employee.shifts > 0 and not employee.shifts[#employee.shifts].endTime then
				local varTime = os.time()
				local shiftLength = varTime - employee.shifts[#employee.shifts].startTime

				dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[uid].shifts[#employee.shifts].endTime = varTime
				dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[uid].shifts[#employee.shifts].length = shiftLength
				msg.channel:send('<@!' .. msg.author.id .. '> , your shift was ended at ' .. os.date('%H:%M:%S %d-%m-%Y', varTime) .. '\nYou worked for: ' .. parseDuration(shiftLength))
			end

		end

		writeData()

		local payCheckString = ''
		local payCheckEmbed = {
			title = args[3]:upper(),
			description = 'Paychecks for ' .. os.date('%d-%m-%Y'),
			author = {
				name = client.user.name,
				icon_url = client.user.avatarURL
			},
			fields = {},
			footer = {
				text = 'Copyright © ' .. os.date('%Y') .. ' ParSec. All Rights Reserved.'
			},
			color = 0xe6e6e6
		}

		for uid, employee in pairs(dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees) do
			if #employee.shifts > 0 then
				local workTime = 0

				for _, shift in ipairs(employee.shifts) do
					workTime = workTime + shift.length
				end

				local employeePosition = ''

				for _, pos in pairs(msg.member.roles:toArray()) do
					if dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[pos.id] then
						employeePosition = pos.id
						break
					end
				end

				local paycheck = 0

				if #employeePosition > 0 then
					paycheck = math.floor((workTime / 3600) * dataTable[msg.guild.id].modules.business.data[args[3]:lower()].positions[employeePosition].wage)
				end

				payCheckString = payCheckString .. '\n<@!' .. uid .. '> worked for **' .. parseDuration(workTime) .. '** and is owed: **$' .. paycheck .. '**'
				local mbdname = msg.guild:getMember(uid).name
				local nickname = msg.guild:getMember(uid).nickname
				local discriminator = msg.guild:getMember(uid).discriminator

				if nickname and nickname ~= name then
					mbdname = 'Name: ' .. mbdname .. '(' .. nickname .. ')'
				end

				mbdname = mbdname .. '#' .. discriminator .. '\nID: ' .. uid

				local mbdTable = {
					name = mbdname,
					value = 'Total work time: ' .. parseDuration(workTime) .. '\nPaycheck: $' .. paycheck,
					inline = false
				}

				table.insert(payCheckEmbed.fields, mbdTable)

				dataTable[msg.guild.id].modules.business.data[args[3]:lower()].employees[uid].shifts = {}
			end
		end

		writeData()

		if #payCheckString <= 0 then
			payCheckString = 'There is noone to calculate for!'
			payCheckEmbed.fields[1] = {
				name = 'There are no paychecks available!',
				value = 'Work harder next time!',
				inline = false
			}
		else
			payCheckString = 'Paychecks:' .. payCheckString
		end

		msg.channel:send(payCheckString)

		if dataTable[msg.guild.id].modules.business.data[args[3]:lower()].shifts_output_channel then
			local textChannel = msg.guild:getChannel(dataTable[msg.guild.id].modules.business.data[args[3]:lower()].shifts_output_channel)
			textChannel:send({embed = payCheckEmbed})
		end
	else
		msg.channel:send('Something went wrong!')
	end
end, 'business')

--@ Command for registering 
createCommand('shift', function(msg, args)
	if args[1]:lower() == 'start' and #args[2]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[2]:lower()] and dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id] and (#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts <= 0 or dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts[#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts].endTime) then
		local varTime = os.time()
		dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts[#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts + 1] = {startTime = varTime}

		msg.channel:send('<@!' .. msg.author.id .. '> , you started your shift at ' .. os.date('%H:%M:%S %d-%m-%Y', varTime))

		writeData()
	elseif args[1]:lower() == 'end'  and #args[2]:lower() >= 3 and dataTable[msg.guild.id].modules.business.data[args[2]:lower()] and dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id] and #dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts > 0 and dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts[#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts].startTime and not dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts[#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts].endTime then
		local varTime = os.time()
		local shiftStartTime = dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts[#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts].startTime
		local shiftLength = varTime - shiftStartTime
		dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts[#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts].endTime = varTime
		dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts[#dataTable[msg.guild.id].modules.business.data[args[2]:lower()].employees[msg.author.id].shifts].length = shiftLength

		msg.channel:send('<@!' .. msg.author.id .. '> , you ended your shift at ' .. os.date('%H:%M:%S %d-%m-%Y', varTime) .. '\nYou worked for: ' .. parseDuration(shiftLength))
		if dataTable[msg.guild.id].modules.business.data[args[2]:lower()].shifts_output_channel then
			local textChannel = msg.guild:getChannel(dataTable[msg.guild.id].modules.business.data[args[2]:lower()].shifts_output_channel)
			textChannel:send({
				content = '<@!' .. msg.author.id .. '>',
				embed = {
					title = args[2]:upper() .. ' - Shift details',
					description = 'Total time: ' .. parseDuration(shiftLength),
					author = {
						name = msg.author.name,
						icon_url = msg.author.avatarURL
					},
					fields = {
						{
							name = 'Start:',
							value = os.date('%H:%M:%S %d-%m-%Y', shiftStartTime),
							inline = false
						},
						{
							name = 'End:',
							value = os.date('%H:%M:%S %d-%m-%Y', varTime),
							inline = false
						}
					},
					footer = {
						text = 'Copyright © ' .. os.date('%Y') .. ' ParSec. All Rights Reserved.'
					},
					color = 0xe6e6e6
				}
			})
		end

		writeData()
	else
		msg.channel:send('Something went wrong!')
	end

end, 'business')

--[[ 
====================================================================================================================
	Discord events
====================================================================================================================
--]]
client:on('guildCreate', function(guild)
	pslog:log(3, 'Joined "' .. guild.name .. '"(' .. guild.id .. ')')
	dataTable[guild.id] = defaultData

	writeData()
end)

client:on('guildDelete', function(guild)
	pslog:log(3, 'Left "' .. guild.name .. '"(' .. guild.id .. ')')

	dataTable[guild.id] = nil

	writeData()
end)

client:on('ready', function()
	pslog:log(3, 'Logged in as ' .. client.user.tag)
	pslog:log(3, 'Serving these guilds:')

	client:setGame(bot_desc)

	readData()

	for _, guild in ipairs(client.guilds:toArray()) do
		pslog:log(3, 'ID: ' .. guild.id .. ' | Name: ' .. guild.name)
		dataTable[guild.id] = dataTable[guild.id] or defaultData

		for k, v in pairs(defaultData.settings) do
			dataTable[guild.id].settings[k] = dataTable[guild.id].settings[k] or v
		end

		for k, v in pairs(defaultData.modules) do
			dataTable[guild.id].modules[k] = dataTable[guild.id].modules[k] or v
		end
	end

	writeData()
end)

client:on('messageCreate', function(msg)
	if msg.author.bot or not msg.guild then return end

	if getModuleData(msg.guild.id, 'darkchat')[msg.channel.id] and getModuleState(msg.guild.id, 'darkchat') then
		msg:delete()

		local randomName = generateRandomString(16, true, false)
		local safeString = string.gsub(msg.content, '(<@!)%d+>', '<REDACTED>')
		safeString = string.gsub(safeString, '(<#)%d+>', '<REDACTED>')

		msg.channel:send({embed = {
				title = 'DarkChat at ' .. os.date('%H:%M:%S %d.%m.%Y'),
				author = {
					name = randomName,
					icon_url = msg.author.avatarURL
				},
				description = '**Message:** ' .. safeString,
				footer = {
					text = client.user.username .. ', Copyright © ' .. os.date('%Y') .. ' ParSec. All rights reserved.'
				},
				color = msg.member.highestRole:getColor().value
			}
		})

		pslog:log(3, 'DarkChat > ' .. randomName .. '(' .. msg.author.tag .. ') > ' .. safeString)
	elseif string.find(msg.content:lower(), '^(!' .. commandsPrefix .. ')') then
		if getSettingState(msg.guild.id, 'enable_channel_whitelist') and not dataTable[msg.guild.id].channelWhitelist[msg.channel.id] and not tableIsEmpty(dataTable[msg.guild.id].channelWhitelist) then return end

		if dataTable[msg.guild.id].userBlacklist[msg.author.id] then
			msg.channel:send('<@!' .. msg.author.id .. '>, you have been blacklisted from using <@!' .. client.user.id .. '> on this server by the creator!')
			pslog:log(2, msg.author.id .. ' is blacklisted from using bot commands')
			return
		end

		local argsTable = string.gsub(msg.content, '^((!.-)%s+)', function(str)
			if string.sub(str:lower(), 1, #commandsPrefix + 1) == '!' .. commandsPrefix then
				return ''
			end
		end)

		argsTable = argsTable:split(' ')
		local cmd = argsTable[1]:lower()
		table.remove(argsTable, 1)

		if commandsTable[cmd] then
			if commandsTable[cmd].moduleName and not getModuleState(msg.guild.id, commandsTable[cmd].moduleName) then
				msg.channel:send(commandsTable[cmd].moduleName .. ' module have been disabled on this server')
				pslog:log(1, msg.author.tag .. ' tried using "' .. commandsTable[cmd].moduleName .. '" which have been disabled for "' .. msg.guild.name .. '"(' .. msg.guild.id .. ')')
				return
			end

			local status, err = pcall(commandsTable[cmd].callback, msg, argsTable)

			if not status then
				msg.channel:send('Please report this to the bot developer!\nPlease provide him this date and time: ' .. os.date('%Y-%m-%d %H-%M-%S'))
				pslog:log(1, msg.guild.name .. '(' .. msg.guild.id .. ') in ' .. msg.channel.name .. '(' .. msg.channel.id .. ')\nError message: ' .. err)
				pslog:log(2, msg.author.tag .. ' tried to run command "' .. cmd .. '" but error was thrown!')
			else
				pslog:log(2, msg.author.tag .. ' ran command "' .. cmd .. '" > ' .. msg.cleanContent)
			end

			return
		end

		msg.channel:send('Invalid command!')
	end
end)

--[[
====================================================================================================================
	Start bot
====================================================================================================================
--]]
local f = io.open('bot.token', 'r')
if not f then
	pslog:log(1, 'There was a problem opening file containing your token!')
	return
end
local token = f:read('*a')
f:close()

client:run('Bot ' .. token)
--[[
====================================================================================================================
	Code End
====================================================================================================================
--]]
