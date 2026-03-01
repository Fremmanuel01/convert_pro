Grover.configure do |config|
  config.options = {
    executable_path: ENV.fetch('PUPPETEER_EXECUTABLE_PATH', '/usr/bin/google-chrome-stable'), # Fallback or dynamic
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
end
