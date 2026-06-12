module.exports = {
  apps: [{
    name: "hermes-gateway",
    script: "venv/Scripts/python.exe",
    args: "-m hermes_cli.main gateway run",
    cwd: "D:/zeno/hermes-agent",
    env: {
      PYTHONIOENCODING: "utf-8",
      PYTHONUTF8: "1",
      DISCORD_PROXY: "socks5://127.0.0.1:7897",
    },
    max_restarts: 30,
    restart_delay: 5000,
    autorestart: true,
    max_memory_restart: "512M",
  }]
};
