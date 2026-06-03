module.exports = {
  apps: [
    {
      name: "knup-app",
      cwd: "/opt/knup/app",
      script: "npm",
      args: "start",
      env: {
        NODE_ENV: "production",
        PORT: 3000,
      },
      instances: 1,
      exec_mode: "fork",
      max_memory_restart: "400M",
      autorestart: true,
      watch: false,
      out_file: "/var/log/knup/out.log",
      error_file: "/var/log/knup/err.log",
      merge_logs: true,
      time: true,
    },
  ],
};
