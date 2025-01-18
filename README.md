# Honey Maker - Archive
### Simple discord bot for roleplay purposes
## Requirements
* [Luvit](https://luvit.io/) version 2.x
* [Discordia](https://github.com/SinisterRectus/Discordia) version 2.9.2

## Commands
**You have to prefix every command with `!<your prefix> `, by default this will be `!hm `**
* `ping` - This will reply with "pong!", useful for checking if your bot is alive.
* `info` - Displays bot info like version and other shit
* `settings` - For changing bot settings per discord server, requires admin privileges, sub commands:
    * `<setting name> set <true/false>` - set selected setting to value
    * `* show` - Show all settings name and status
* `modules` - Enabling and disabling modules for each discord server, only bot owner, sub commands
    * `enable <module name>` - enables selected module
    * `disable <module name>` - disables selected modules
* `blacklist` - Broken as fuck, don't even try to use it.
* `whitelist` - Command for managing channel whitelist, mainly to stop bot spam, sub commands:
    * `add <channel tag>` - Adds channel to whitelist
    * `remove <channel tag>` - Removes channel from whitelist
    * `list` - Lists all whitelisted channels
* `darkchat` - For managing darkchat channels, part of darkchat module
    * `add <channel tag>` - Transforms tagged channel into darkchat
    * `remove <channel tag>` - Transforms tagged channel back into normal
* `business` - business module main command
    * `set` - for setting the settings of businesses
        * `owner <business name> <user tag>` - sets the owner of business
        * `wage <business name> <discord role tag>` - sets wage for discord role
        * `shifts_output_channel <business name> <channel tag>` - Redirects log and output of shifts to set channel
    * `add` - sub command for adding shit into businesses
        * `business <business name>` - Creates business
        * `hr <business name> <user tag>` - Enables user to hire people
        * `employee <business name> <user tag>` - Adds user to business
        * `position <business name> <discord role tag>`
    * `remove` - sub commands for removing shit from busineses
        * `business <business name>` - Removes business
        * `hr <business name> <user tag>` - Strips ability to hire people from person
        * `employee <business name> <user tag>` - Removes person from business
        * `position <business name> <discord role tag>` - Removes disocrd role from being position in business
    * `calculate paychecks` - stops everyones shifts if any are active and calculate paychecks for everyone and sends them to channel.
* `shift` - this command is part of business module
    * `start <business name>` - Command for starting shift by an employee
    * `end <business name>` - Command to end your current shift

## Settings
**Wow! So much settings!**
* `enable_channel_whitelist` - Enables channel whitelist to prevent bot spam (remember to add at least one channel into whitelist before enabling this option)

## Modules
* `dakrchat` - Module that removes original message and sends more encrypted version
* `business` - Module that helps with managing businesses on roleplay server

## Installation
1. Run `install.bat` or `install.sh` depending on your OS
2. Copy `bot.token.default` into `bot.token`
3. Insert your bot token into `bot.token`
4. Config the bot to your likings using `config.lua` (not much there but meybe something)
5. Start the bot using either `run.bat` or `run.sh` depending on your OS

## Disclaimer
**This will not receive any updates, it is what it is**
