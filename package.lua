  return {
    name = "LunaStream/Starie",
    version = "1.0.0",
    description = "An example bot for LunaStream",
    tags = { "lua", "lit", "luvit" },
    license = "BSD-3",
    author = { name = "RainyXeon", email = "xeondev@xeondex.onmicrosoft.com" },
    homepage = "https://github.com/LunaStream/Starie",
    dependencies = {
      'RainyXeon/discordia@v3.0.8',
      'RainyXeon/lunalink@v0.0.3',
      'luvit/luvit@v2.18.1',
      '4keef/Dotenv@v0.0.6'
    },
    files = {
      "**.lua",
      "!test*"
    }
  }
  