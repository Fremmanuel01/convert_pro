Grover.configure do |config|
  config.options = {
    executable_path: ENV.fetch('PUPPETEER_EXECUTABLE_PATH', '/usr/bin/chromium'), # standard path for chromium on debian
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
end
