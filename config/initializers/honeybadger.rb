Honeybadger.configure do |config|
  # SQLite allows one writer. When fly stops the machine, the Solid Queue
  # dispatcher can be mid-transaction while the supervisor tears down, and it
  # loses the lock on the way out. Honeybadger's at_exit hook reports that as a
  # fault, but there is nothing to fix in a process that is already gone.
  #
  # Scoped to at_exit only — a busy error during a request or a running job is
  # real contention and still reports.
  config.before_notify do |notice|
    notice.halt! if notice.component == "at_exit" && notice.error_message.include?("database is locked")
  end
end
