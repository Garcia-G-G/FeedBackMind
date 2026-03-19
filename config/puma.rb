threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)

workers ENV.fetch("WEB_CONCURRENCY", 2)

preload_app!

plugin :tmp_restart

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
