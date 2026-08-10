Honeybadger.configure do |config|
  # A stopping machine kills the Solid Queue dispatcher mid-transaction — nothing to
  # fix in a dead process. Scoped to at_exit: a busy error during a request or a
  # running job is real contention and still reports.
  config.before_notify do |notice|
    notice.halt! if notice.component == "at_exit" && notice.error_message.include?("database is locked")
  end
end
