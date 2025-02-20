local discordia = require('discordia')
local Dotenv = require('Dotenv')
local lunalink = require('lunalink')

local client = discordia.Client({
  gatewayIntents = 53608447
})
local f = string.format
local LunaStreamDriver = require('./driver')

Dotenv.load_env('./.env')

CURR = {
  guild_id = '1027945618347397220',
  user_id = '977148321682575410',
  session_id = 'none',
  endpoint = 'none',
  token = 'none'
}

print(
  Dotenv.get_value("NODE_NAME"),
  Dotenv.get_value("NODE_HOST"),
  Dotenv.get_value("NODE_SECURE") == "true" and true or false,
  Dotenv.get_value("NODE_AUTH"),
  Dotenv.get_value("NODE_PORT"),
  Dotenv.get_value("NODE_DRIVER")
)

local manager = lunalink.Core({
  additionalDriver = { LunaStreamDriver },
  nodes = {
    {
      name = Dotenv.get_value("NODE_NAME"),
      host = Dotenv.get_value("NODE_HOST"),
      secure = Dotenv.get_value("NODE_SECURE") == "true" and true or false,
      auth = Dotenv.get_value("NODE_AUTH"),
      port = tonumber(Dotenv.get_value("NODE_PORT")),
      driver = Dotenv.get_value("NODE_DRIVER")
    }
  },
  library = lunalink.library.Discordia(client),
})

manager:on('debug', function (log)
  print(log)
end)

manager:on('nodeConnect', function (node)
  print(f("LunaStream [%s] Ready!", node.options.name))
end)

manager:on('nodeError', function (node, err)
  print(f("LunaStream [%s] error: %s", node.options.name, err))
end)

manager:on('nodeClosed', function (node)
  print(f("LunaStream [%s] Closed!", node.options.name))
end)

manager:on('nodeDisconnect', function (node, code, reason)
  print(f("LunaStream [%s] Disconnected, Code %s, Reason %s", node.options.name, code, reason))
end)

manager:on("trackStart", function (player, track)
  client.guilds:get(player.guildId).textChannels:get(player.textId):send(
    f("Now playing **%s** by **%s**", track.title, track.author)
  )
end);

manager:on("trackEnd", function (player)
  client.guilds:get(player.guildId).textChannels:get(player.textId):send(
    "Finished playing"
  )
end);

manager:on("queueEmpty", function (player)
  client.guilds:get(player.guildId).textChannels:get(player.textId):send(
    "Destroyed player due to inactivity."
  )
  player:destroy()
end);

client:on('messageCreate', function (message)
  if message.author.bot then return end
  local is_join = string.match(message.content, "%!join")

  if is_join then
    local channel = message.member.voiceChannel
    if not channel then return message:reply("You need to be in a voice channel to use this command!") end
    local player = manager.players:get(message.guild.id)
    if player then
      return message:reply({ content = "Player joined" })
    end
    manager.players:create({
      guildId = message.guild.id,
      textId = message.channel.id,
      voiceId = channel.id,
      shardId = 0,
      volume = 100
    })
    return message:reply({ content = "Player joined" })
  end

  local play_q = string.match(message.content, "%!play (.+)")

  if play_q then
    local channel = message.member.voiceChannel
    if not channel then return message:reply("You need to be in a voice channel to use this command!") end

    local player = manager.players:create({
      guildId = message.guild.id,
      textId = message.channel.id,
      voiceId = channel.id,
      shardId = 0,
      volume = 100
    })

    local result = manager:search(play_q, { requester = message.author })
    if #result.tracks == 0 then return message:reply("No results found!") end

    if result.type == "PLAYLIST" then
      for _, track in pairs(result.tracks) do
        player.queue:add(track)
      end
    else player.queue:add(result.tracks[1]) end

    if not player.playing then player:play() end

    return message:reply({ content = f("Queued %s", result.tracks[1].title) });
  end

  local is_stop = string.match(message.content, "%!stop")

  if is_stop then
    local player = manager.players:get(message.guild.id)
    if player then
      player:destroy()
      return message:reply({ content = "Player desstroyed" })
    end
    return message:reply({ content = "No player have to destroy" })
  end

  local track_q = string.match(message.content, "%!track (.+)")

  if track_q then
    local result = manager:search(track_q, { requester = message.author })
    if #result.tracks == 0 then return message:reply("No results found!") end

    return message:reply({ content = require('json').encode(result.tracks[1].raw) });
  end
end)

client:run(Dotenv.get_value("BOT_TOKEN"))