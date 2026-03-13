Grover.configure do |config|
  opts = {
    print_background: true,
    wait_until: 'networkidle2',
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu']
  }

  # Only set executable_path if explicitly configured (production/Docker).
  # In development, Puppeteer will use its bundled Chromium or system Chrome.
  if ENV['PUPPETEER_EXECUTABLE_PATH'].present?
    opts[:executable_path] = ENV['PUPPETEER_EXECUTABLE_PATH']
  elsif File.exist?('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
    opts[:executable_path] = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
  end

  config.options = opts
end
