web: bin/rails db:migrate && bundle exec puma -C config/puma.rb
worker: bin/rails db:prepare && bundle exec rake solid_queue:start
